// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


/// @title ERC20 interface
/// @notice The interface of our ERC20 token
/// @author CakeTogether
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


// File contracts/interfaces/ITOGE.sol

/// @title TOGE Token Interface
/// @notice The interface of our TOGE token
/// @author CakeTogether
interface ITOGE is IERC20 {
    /// @notice Mints tokens
    /// @dev Only callable by the current minter
    /// @param to The recipient of the tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @notice Updates the minter
    /// @dev Only callable by the current minter
    /// @param newMinter The address of the new minter
    function updateMinter(address newMinter) external;

    /// @notice Returns the current minter
    /// @return The address of the current minter
    function minter() external view returns (address);

    /// @notice The maximum supply of TOGE
    function maxSupply() external view returns (uint256);
}


// File contracts/ERC20.sol

/// @notice ERC20 token
/// @notice A classic ERC20 token contract
/// @author CakeTogether
contract ERC20 is IERC20 {
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;
    uint8 public override decimals;

    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount) external override virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "Amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual { }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(balanceOf[sender] >= amount, "Transfer amount exceeds balance");

        _beforeTokenTransfer(sender, recipient, amount);

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balanceOf[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        require(balanceOf[account] >= amount, "Insufficient balance");

        _beforeTokenTransfer(account, address(0), amount);

        totalSupply -= amount;
        balanceOf[account] -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}


// File contracts/TOGE.sol

/// @title TOGE
/// @notice CakeTogether governance token
/// @author CakeTogether
contract TOGE is ITOGE, ERC20 {
    /// @inheritdoc ITOGE
    address public override minter;

    /// @inheritdoc ITOGE
    uint256 public override maxSupply;

    /// @param _minter The address of the minter
    constructor(
        address _minter,
        uint256 _maxSupply
    ) ERC20(
        "CakeTogether",
        "TOGE",
        18
    ) {
        minter = _minter;
        maxSupply = _maxSupply;
    }

    /// @inheritdoc ITOGE
    function updateMinter(address newMinter) external override {
        require(minter == msg.sender, "Not minter");
        minter = newMinter;
    }

    /// @inheritdoc ITOGE
    function mint(address to, uint256 amount) external override {
        require(msg.sender == minter, "Only minter");
        require(totalSupply + amount <= maxSupply, "Max supply reached");
        _mint(to, amount);
    }
}
