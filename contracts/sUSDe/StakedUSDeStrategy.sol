// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {BaseERC20Strategy} from "yieldbox/strategies/BaseStrategy.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IYieldBox} from "yieldbox/interfaces/IYieldBox.sol";

// Tapioca Yieldbox
import {IStakedUSDe} from "./interfaces/IStakedUSDe.sol";
import {ITUSDe} from "./interfaces/ITUSDe.sol";
import {IStakedUSDeStrategy} from "./interfaces/IStakedUSDeStrategy.sol";

/// @title Staking Strategy for tUSDe Tapioca YieldBox
/// @author David Canillas Racero
/// @notice Do NOT use or interact with this contract in production, source code has not been audited or reviewed by a third party.

/// @dev sUSDe is a staking contract for USDe that does NOT follow ERC4626 standard for withdrawals. If sUSDE.cooldownDuration() is > 0, you must call sUSDe.cooldownShares() and wait cooldownDuration before calling sUSDe.unstake().
contract StakedUSDeStrategy is IStakedUSDeStrategy, BaseERC20Strategy, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ICluster internal _cluster;

    IStakedUSDe public immutable SUSDE;
    IERC20 public immutable USDE;

    bool public depositPaused;
    bool public withdrawPaused;

    /// @notice Queues tokens up to depositThreshold
    /// @dev When the amount of tokens is greater than the threshold, a deposit operation is performed
    uint256 public depositThreshold;

    /// @notice Deploy StakedUSDeStrategy
    /// @param yieldBox The YieldBox address
    /// @param tUSDe The tUSDe address
    /// @param sUSDe The sUSDe address
    /// @param admin The admin address that will own this instance
    constructor(IYieldBox yieldBox, address tUSDe, IStakedUSDe sUSDe, address admin)
        BaseERC20Strategy(yieldBox, tUSDe)
    {
        SUSDE = sUSDe;
        USDE = IERC20(ITUSDe(tUSDe).erc20());
        if (address(USDE) != SUSDE.asset()) revert TokenNotValid();

        transferOwnership(admin);
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice Returns the name of this strategy
    function name() external pure override returns (string memory) {
        return "sUSDe-tap-yieldbox";
    }

    /// @notice Returns the description of this strategy
    function description() external pure override returns (string memory) {
        return "sUSDe strategy for tUSDe assets";
    }

    /// @notice Returns the unharvested token gains
    /// @dev If the cooldown duration is greater than 0, it returns the cooldown amount, otherwise the max withdrawable amount
    function harvestable() external view returns (uint256 result) {
        if (SUSDE.cooldownDuration() > 0) {
            (, result) = SUSDE.cooldowns(address(this));
        } else {
            result = SUSDE.maxWithdraw(address(this));
        }
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //

    /// @notice Call cooldownAssets on the sUSDe contract to be able to withdraw USDe.
    function cooldownAssets(uint256 amount) external {
        if (!_cluster.hasRole(msg.sender, keccak256("COOLDOWN_ADMIN")) && msg.sender != owner()) {
            revert CooldownNotAuthorized();
        }
        SUSDE.cooldownAssets(amount);
    }

    /// @notice Call cooldownShares on the sUSDe contract to be able to withdraw USDe.
    function cooldownShares(uint256 shares) external {
        if (!_cluster.hasRole(msg.sender, keccak256("COOLDOWN_ADMIN")) && msg.sender != owner()) {
            revert CooldownNotAuthorized();
        }
        SUSDE.cooldownShares(shares);
    }

    /// @notice updates the pause state
    /// @param _val the new state
    /// @param depositType if true, pause refers to deposits
    function setPause(bool _val, PauseType depositType) external {
        if (!_cluster.hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) revert PauserNotAuthorized();

        if (depositType == PauseType.Deposit) {
            emit Paused(depositPaused, _val, true);
            depositPaused = _val;
        } else {
            emit Paused(withdrawPaused, _val, false);
            withdrawPaused = _val;
        }
    }

    /// @notice rescues unused ETH from the contract
    /// @param amount the amount to rescue
    /// @param to the recipient
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Sets the deposit threshold
    /// @param amount The new threshold amount
    function setDepositThreshold(uint256 amount) external onlyOwner {
        emit DepositThreshold(depositThreshold, amount);
        depositThreshold = amount;
    }

    /// @notice withdraws everything from the strategy
    /// @dev Withdraws everything from the strategy and pauses it.
    ///      If SUSDE cooldown greater than 0, them to withdraw you must call "StakedUSDEStrategy.cooldownShares()" and
    ///      wait SUSDE.cooldownDuration() before calling StakedUSDEStrategy.emergencyWithdraw().
    function emergencyWithdraw() external onlyOwner {
        // Pause the strategy
        depositPaused = true;
        withdrawPaused = true;
        uint256 maxWithdraw;

        if (SUSDE.cooldownDuration() > 0) {
            (, maxWithdraw) = SUSDE.cooldowns(address(this));
            SUSDE.unstake(address(this));
        } else {
            maxWithdraw = SUSDE.maxWithdraw(address(this));
            SUSDE.withdraw(maxWithdraw, address(this), address(this));
        }

        USDE.approve(contractAddress, maxWithdraw);
        ITUSDe(contractAddress).wrap(address(this), address(this), maxWithdraw);
    }

    /**
     * @notice updates the Cluster address.
     * @dev can only be called by the owner.
     * @param newCluster the new address.
     */
    function setCluster(ICluster newCluster) external onlyOwner {
        if (address(newCluster) == address(0)) revert EmptyAddress();
        emit ClusterUpdated(_cluster, newCluster);
        _cluster = newCluster;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //

    /// @notice Returns the amount of USDe in the pool plus the amount that can be withdrawn from the contract
    function _currentBalance() internal view override returns (uint256 amount) {
        uint256 maxWithdraw = SUSDE.maxWithdraw(address(this));
        uint256 queued = IERC20(contractAddress).balanceOf(address(this));
        return maxWithdraw + queued;
    }

    /// @dev deposits to sUSDe or queues tokens if the 'depositThreshold' has not been met yet
    function _deposited(uint256 amount) internal override nonReentrant {
        if (depositPaused) revert DepositPaused();

        // Assume that YieldBox already transferred the tokens to this address
        uint256 queued = IERC20(contractAddress).balanceOf(address(this));

        if (queued >= depositThreshold) {
            ITUSDe(contractAddress).unwrap(address(this), queued);
            USDE.approve(address(SUSDE), queued);
            SUSDE.deposit(queued, address(this));
            emit AmountDeposited(queued);
            return;
        }
        emit AmountQueued(amount);
    }

    /// @dev burns sUSDE in exchange of USDE and wraps it into tUSDe
    ///      If SUSDE cooldown greater than 0, them to withdraw you must call "StakedUSDEStrategy.cooldownShares()" and
    ///      wait SUSDE.cooldownDuration() before calling StakedUSDEStrategy.withdraw().
    function _withdraw(address to, uint256 amount) internal override nonReentrant {
        if (withdrawPaused) revert WithdrawPaused();

        uint256 maxWithdraw;
        uint256 cooldown = SUSDE.cooldownDuration();

        if (cooldown > 0) {
            (, maxWithdraw) = SUSDE.cooldowns(address(this));
        } else {
            maxWithdraw = SUSDE.maxWithdraw(address(this)); // Total amount of USDe that can be withdrawn from the pool
        }
        uint256 assetInContract = IERC20(contractAddress).balanceOf(address(this));

        if (assetInContract + maxWithdraw < amount) revert NotEnough(); // NOTICE: usde <> tUSDE is NOT 1:1, tUSDE implementation contract must handle rebasing

        uint256 toWithdrawFromPool;
        // Amount externally passed, but is already checked to be in realistic boundaries.
        unchecked {
            toWithdrawFromPool = amount > assetInContract ? amount - assetInContract : 0; // Asset to withdraw from the pool if not enough available in the contract
        }

        // If there is nothing to withdraw from the pool, just transfer the tokens and return
        if (toWithdrawFromPool == 0) {
            IERC20(contractAddress).safeTransfer(to, amount);
            emit AmountWithdrawn(to, amount);
            return;
        }

        // Withdraw from the pool, convert to USDe and wrap it into tUSDe
        if (cooldown > 0) {
            SUSDE.unstake(address(this));
        } else {
            SUSDE.withdraw(toWithdrawFromPool, address(this), address(this));
        }
        USDE.approve(contractAddress, toWithdrawFromPool);
        ITUSDe(contractAddress).wrap(address(this), address(this), toWithdrawFromPool);

        // Transfer the requested amount
        IERC20(contractAddress).safeTransfer(to, amount);
        emit AmountWithdrawn(to, amount);
    }

    receive() external payable {}
}
