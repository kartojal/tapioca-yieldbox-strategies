// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @dev Solidity interface for StakedUSDeV2 generated with gnidan/abi-to-sol https://gnidan.github.io/abi-to-sol
interface IStakedUSDe {
    error CantBlacklistOwner();
    error ExcessiveRedeemAmount();
    error ExcessiveWithdrawAmount();
    error InvalidAdminChange();
    error InvalidAmount();
    error InvalidCooldown();
    error InvalidShortString();
    error InvalidToken();
    error InvalidZeroAddress();
    error MinSharesViolation();
    error NotPendingAdmin();
    error OperationNotAllowed();
    error StillVesting();
    error StringTooLong(string str);
    event AdminTransferRequested(
        address indexed oldAdmin,
        address indexed newAdmin
    );
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event CooldownDurationUpdated(uint24 previousDuration, uint24 newDuration);
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event EIP712DomainChanged();
    event LockedAmountRedistributed(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event RewardsReceived(uint256 amount);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MAX_COOLDOWN_DURATION() external view returns (uint24);

    function acceptAdmin() external;

    function addToBlacklist(address target, bool isFullBlacklisting) external;

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function cooldownAssets(uint256 assets) external returns (uint256 shares);

    function cooldownDuration() external view returns (uint24);

    function cooldownShares(uint256 shares) external returns (uint256 assets);

    function cooldowns(
        address
    ) external view returns (uint104 cooldownEnd, uint152 underlyingAmount);

    function decimals() external pure returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256);

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getUnvestedAmount() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function lastDistributionTimestamp() external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function owner() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address _owner
    ) external returns (uint256);

    function redistributeLockedAmount(address from, address to) external;

    function removeFromBlacklist(
        address target,
        bool isFullBlacklisting
    ) external;

    function renounceRole(bytes32, address) external;

    function rescueTokens(address token, uint256 amount, address to) external;

    function revokeRole(bytes32 role, address account) external;

    function setCooldownDuration(uint24 duration) external;

    function silo() external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferAdmin(address newAdmin) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferInRewards(uint256 amount) external;

    function unstake(address receiver) external;

    function vestingAmount() external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address _owner
    ) external returns (uint256);
}
