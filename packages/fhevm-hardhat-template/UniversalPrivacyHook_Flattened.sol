// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;



// node_modules/@uniswap/v4-core/src/types/BeforeSwapDelta.sol

// Return type of the beforeSwap hook.
// Upper 128 bits is the delta in specified tokens. Lower 128 bits is delta in unspecified tokens (to match the afterSwap hook)
type BeforeSwapDelta is int256;

// Creates a BeforeSwapDelta from specified and unspecified
function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(shl(128, deltaSpecified), and(sub(shl(128, 1), 1), deltaUnspecified))
    }
}

/// @notice Library for getting the specified and unspecified deltas from the BeforeSwapDelta type
library BeforeSwapDeltaLibrary {
    /// @notice A BeforeSwapDelta of 0
    BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);

    /// extracts int128 from the upper 128 bits of the BeforeSwapDelta
    /// returned by beforeSwap
    function getSpecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaSpecified) {
        assembly ("memory-safe") {
            deltaSpecified := sar(128, delta)
        }
    }

    /// extracts int128 from the lower 128 bits of the BeforeSwapDelta
    /// returned by beforeSwap and afterSwap
    function getUnspecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaUnspecified) {
        assembly ("memory-safe") {
            deltaUnspecified := signextend(15, delta)
        }
    }
}

// node_modules/@uniswap/v4-core/src/libraries/BitMath.sol

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
/// @author Solady (https://github.com/Vectorized/solady/blob/8200a70e8dc2a77ecb074fc2e99a2a0d36547522/src/utils/LibBit.sol)
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        assembly ("memory-safe") {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // forgefmt: disable-next-item
            r := or(r, byte(and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
                0x0706060506020500060203020504000106050205030304010505030400000000))
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        assembly ("memory-safe") {
            // Isolate the least significant bit.
            x := and(x, sub(0, x))
            // For the upper 3 bits of the result, use a De Bruijn-like lookup.
            // Credit to adhusson: https://blog.adhusson.com/cheap-find-first-set-evm/
            // forgefmt: disable-next-item
            r := shl(5, shr(252, shl(shl(2, shr(250, mul(x,
                0xb6db6db6ddddddddd34d34d349249249210842108c6318c639ce739cffffffff))),
                0x8040405543005266443200005020610674053026020000107506200176117077)))
            // For the lower 5 bits of the result, use a De Bruijn lookup.
            // forgefmt: disable-next-item
            r := or(r, byte(and(div(0xd76453e0, shr(r, x)), 0x1f),
                0x001f0d1e100c1d070f090b19131c1706010e11080a1a141802121b1503160405))
        }
    }
}

// node_modules/@openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// node_modules/@uniswap/v4-core/src/libraries/CustomRevert.sol

/// @title Library for reverting with custom errors efficiently
/// @notice Contains functions for reverting with custom errors with different argument types efficiently
/// @dev To use this library, declare `using CustomRevert for bytes4;` and replace `revert CustomError()` with
/// `CustomError.selector.revertWith()`
/// @dev The functions may tamper with the free memory pointer but it is fine since the call context is exited immediately
library CustomRevert {
    /// @dev ERC-7751 error for wrapping bubbled up reverts
    error WrappedError(address target, bytes4 selector, bytes reason, bytes details);

    /// @dev Reverts with the selector of a custom error in the scratch space
    function revertWith(bytes4 selector) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            revert(0, 0x04)
        }
    }

    /// @dev Reverts with a custom error with an address argument in the scratch space
    function revertWith(bytes4 selector, address addr) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, and(addr, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with an int24 argument in the scratch space
    function revertWith(bytes4 selector, int24 value) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, signextend(2, value))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with a uint160 argument in the scratch space
    function revertWith(bytes4 selector, uint160 value) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, and(value, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with two int24 arguments
    function revertWith(bytes4 selector, int24 value1, int24 value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), signextend(2, value1))
            mstore(add(fmp, 0x24), signextend(2, value2))
            revert(fmp, 0x44)
        }
    }

    /// @dev Reverts with a custom error with two uint160 arguments
    function revertWith(bytes4 selector, uint160 value1, uint160 value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), and(value1, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(fmp, 0x24), and(value2, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(fmp, 0x44)
        }
    }

    /// @dev Reverts with a custom error with two address arguments
    function revertWith(bytes4 selector, address value1, address value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), and(value1, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(fmp, 0x24), and(value2, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(fmp, 0x44)
        }
    }

    /// @notice bubble up the revert message returned by a call and revert with a wrapped ERC-7751 error
    /// @dev this method can be vulnerable to revert data bombs
    function bubbleUpAndRevertWith(
        address revertingContract,
        bytes4 revertingFunctionSelector,
        bytes4 additionalContext
    ) internal pure {
        bytes4 wrappedErrorSelector = WrappedError.selector;
        assembly ("memory-safe") {
            // Ensure the size of the revert data is a multiple of 32 bytes
            let encodedDataSize := mul(div(add(returndatasize(), 31), 32), 32)

            let fmp := mload(0x40)

            // Encode wrapped error selector, address, function selector, offset, additional context, size, revert reason
            mstore(fmp, wrappedErrorSelector)
            mstore(add(fmp, 0x04), and(revertingContract, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(
                add(fmp, 0x24),
                and(revertingFunctionSelector, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            )
            // offset revert reason
            mstore(add(fmp, 0x44), 0x80)
            // offset additional context
            mstore(add(fmp, 0x64), add(0xa0, encodedDataSize))
            // size revert reason
            mstore(add(fmp, 0x84), returndatasize())
            // revert reason
            returndatacopy(add(fmp, 0xa4), 0, returndatasize())
            // size additional context
            mstore(add(fmp, add(0xa4, encodedDataSize)), 0x04)
            // additional context
            mstore(
                add(fmp, add(0xc4, encodedDataSize)),
                and(additionalContext, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            )
            revert(fmp, add(0xe4, encodedDataSize))
        }
    }
}

// node_modules/encrypted-types/EncryptedTypes.sol

type ebool is bytes32;

type euint8 is bytes32;
type euint16 is bytes32;
type euint24 is bytes32;
type euint32 is bytes32;
type euint40 is bytes32;
type euint48 is bytes32;
type euint56 is bytes32;
type euint64 is bytes32;
type euint72 is bytes32;
type euint80 is bytes32;
type euint88 is bytes32;
type euint96 is bytes32;
type euint104 is bytes32;
type euint112 is bytes32;
type euint120 is bytes32;
type euint128 is bytes32;
type euint136 is bytes32;
type euint144 is bytes32;
type euint152 is bytes32;
type euint160 is bytes32;
type euint168 is bytes32;
type euint176 is bytes32;
type euint184 is bytes32;
type euint192 is bytes32;
type euint200 is bytes32;
type euint208 is bytes32;
type euint216 is bytes32;
type euint224 is bytes32;
type euint232 is bytes32;
type euint240 is bytes32;
type euint248 is bytes32;
type euint256 is bytes32;

type eint8 is bytes32;
type eint16 is bytes32;
type eint24 is bytes32;
type eint32 is bytes32;
type eint40 is bytes32;
type eint48 is bytes32;
type eint56 is bytes32;
type eint64 is bytes32;
type eint72 is bytes32;
type eint80 is bytes32;
type eint88 is bytes32;
type eint96 is bytes32;
type eint104 is bytes32;
type eint112 is bytes32;
type eint120 is bytes32;
type eint128 is bytes32;
type eint136 is bytes32;
type eint144 is bytes32;
type eint152 is bytes32;
type eint160 is bytes32;
type eint168 is bytes32;
type eint176 is bytes32;
type eint184 is bytes32;
type eint192 is bytes32;
type eint200 is bytes32;
type eint208 is bytes32;
type eint216 is bytes32;
type eint224 is bytes32;
type eint232 is bytes32;
type eint240 is bytes32;
type eint248 is bytes32;
type eint256 is bytes32;

type eaddress is bytes32;

type ebytes1 is bytes32;
type ebytes2 is bytes32;
type ebytes3 is bytes32;
type ebytes4 is bytes32;
type ebytes5 is bytes32;
type ebytes6 is bytes32;
type ebytes7 is bytes32;
type ebytes8 is bytes32;
type ebytes9 is bytes32;
type ebytes10 is bytes32;
type ebytes11 is bytes32;
type ebytes12 is bytes32;
type ebytes13 is bytes32;
type ebytes14 is bytes32;
type ebytes15 is bytes32;
type ebytes16 is bytes32;
type ebytes17 is bytes32;
type ebytes18 is bytes32;
type ebytes19 is bytes32;
type ebytes20 is bytes32;
type ebytes21 is bytes32;
type ebytes22 is bytes32;
type ebytes23 is bytes32;
type ebytes24 is bytes32;
type ebytes25 is bytes32;
type ebytes26 is bytes32;
type ebytes27 is bytes32;
type ebytes28 is bytes32;
type ebytes29 is bytes32;
type ebytes30 is bytes32;
type ebytes31 is bytes32;
type ebytes32 is bytes32;

type externalEbool is bytes32;

type externalEuint8 is bytes32;
type externalEuint16 is bytes32;
type externalEuint24 is bytes32;
type externalEuint32 is bytes32;
type externalEuint40 is bytes32;
type externalEuint48 is bytes32;
type externalEuint56 is bytes32;
type externalEuint64 is bytes32;
type externalEuint72 is bytes32;
type externalEuint80 is bytes32;
type externalEuint88 is bytes32;
type externalEuint96 is bytes32;
type externalEuint104 is bytes32;
type externalEuint112 is bytes32;
type externalEuint120 is bytes32;
type externalEuint128 is bytes32;
type externalEuint136 is bytes32;
type externalEuint144 is bytes32;
type externalEuint152 is bytes32;
type externalEuint160 is bytes32;
type externalEuint168 is bytes32;
type externalEuint176 is bytes32;
type externalEuint184 is bytes32;
type externalEuint192 is bytes32;
type externalEuint200 is bytes32;
type externalEuint208 is bytes32;
type externalEuint216 is bytes32;
type externalEuint224 is bytes32;
type externalEuint232 is bytes32;
type externalEuint240 is bytes32;
type externalEuint248 is bytes32;
type externalEuint256 is bytes32;

type externalEint8 is bytes32;
type externalEint16 is bytes32;
type externalEint24 is bytes32;
type externalEint32 is bytes32;
type externalEint40 is bytes32;
type externalEint48 is bytes32;
type externalEint56 is bytes32;
type externalEint64 is bytes32;
type externalEint72 is bytes32;
type externalEint80 is bytes32;
type externalEint88 is bytes32;
type externalEint96 is bytes32;
type externalEint104 is bytes32;
type externalEint112 is bytes32;
type externalEint120 is bytes32;
type externalEint128 is bytes32;
type externalEint136 is bytes32;
type externalEint144 is bytes32;
type externalEint152 is bytes32;
type externalEint160 is bytes32;
type externalEint168 is bytes32;
type externalEint176 is bytes32;
type externalEint184 is bytes32;
type externalEint192 is bytes32;
type externalEint200 is bytes32;
type externalEint208 is bytes32;
type externalEint216 is bytes32;
type externalEint224 is bytes32;
type externalEint232 is bytes32;
type externalEint240 is bytes32;
type externalEint248 is bytes32;
type externalEint256 is bytes32;

type externalEaddress is bytes32;

type externalEbytes1 is bytes32;
type externalEbytes2 is bytes32;
type externalEbytes3 is bytes32;
type externalEbytes4 is bytes32;
type externalEbytes5 is bytes32;
type externalEbytes6 is bytes32;
type externalEbytes7 is bytes32;
type externalEbytes8 is bytes32;
type externalEbytes9 is bytes32;
type externalEbytes10 is bytes32;
type externalEbytes11 is bytes32;
type externalEbytes12 is bytes32;
type externalEbytes13 is bytes32;
type externalEbytes14 is bytes32;
type externalEbytes15 is bytes32;
type externalEbytes16 is bytes32;
type externalEbytes17 is bytes32;
type externalEbytes18 is bytes32;
type externalEbytes19 is bytes32;
type externalEbytes20 is bytes32;
type externalEbytes21 is bytes32;
type externalEbytes22 is bytes32;
type externalEbytes23 is bytes32;
type externalEbytes24 is bytes32;
type externalEbytes25 is bytes32;
type externalEbytes26 is bytes32;
type externalEbytes27 is bytes32;
type externalEbytes28 is bytes32;
type externalEbytes29 is bytes32;
type externalEbytes30 is bytes32;
type externalEbytes31 is bytes32;
type externalEbytes32 is bytes32;

// node_modules/@fhevm/solidity/lib/FheType.sol

enum FheType {
    Bool,
    Uint4,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Uint128,
    Uint160,
    Uint256,
    Uint512,
    Uint1024,
    Uint2048,
    Uint2,
    Uint6,
    Uint10,
    Uint12,
    Uint14,
    Int2,
    Int4,
    Int6,
    Int8,
    Int10,
    Int12,
    Int14,
    Int16,
    Int32,
    Int64,
    Int128,
    Int160,
    Int256,
    AsciiString,
    Int512,
    Int1024,
    Int2048,
    Uint24,
    Uint40,
    Uint48,
    Uint56,
    Uint72,
    Uint80,
    Uint88,
    Uint96,
    Uint104,
    Uint112,
    Uint120,
    Uint136,
    Uint144,
    Uint152,
    Uint168,
    Uint176,
    Uint184,
    Uint192,
    Uint200,
    Uint208,
    Uint216,
    Uint224,
    Uint232,
    Uint240,
    Uint248,
    Int24,
    Int40,
    Int48,
    Int56,
    Int72,
    Int80,
    Int88,
    Int96,
    Int104,
    Int112,
    Int120,
    Int136,
    Int144,
    Int152,
    Int168,
    Int176,
    Int184,
    Int192,
    Int200,
    Int208,
    Int216,
    Int224,
    Int232,
    Int240,
    Int248
}

// node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// node_modules/@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns an account's balance in the token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// node_modules/@uniswap/v4-core/src/interfaces/external/IERC6909Claims.sol

/// @notice Interface for claims over a contract balance, wrapped as a ERC6909
interface IERC6909Claims {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OperatorSet(address indexed owner, address indexed operator, bool approved);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner balance of an id.
    /// @param owner The address of the owner.
    /// @param id The id of the token.
    /// @return amount The balance of the token.
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);

    /// @notice Spender allowance of an id.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @return amount The allowance of the token.
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);

    /// @notice Checks if a spender is approved by an owner as an operator
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @return approved The approval status.
    function isOperator(address owner, address spender) external view returns (bool approved);

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always, unless the function reverts
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always, unless the function reverts
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /// @notice Sets or removes an operator for the caller.
    /// @param operator The address of the operator.
    /// @param approved The approval status.
    /// @return bool True, always
    function setOperator(address operator, bool approved) external returns (bool);
}

// node_modules/@uniswap/v4-core/src/interfaces/IExtsload.sol

/// @notice Interface for functions to access any storage slot in a contract
interface IExtsload {
    /// @notice Called by external contracts to access granular pool state
    /// @param slot Key of slot to sload
    /// @return value The value of the slot as bytes32
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access granular pool state
    /// @param startSlot Key of slot to start sloading from
    /// @param nSlots Number of slots to load into return value
    /// @return values List of loaded values.
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory values);

    /// @notice Called by external contracts to access sparse pool state
    /// @param slots List of slots to SLOAD from.
    /// @return values List of loaded values.
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}

// node_modules/@uniswap/v4-core/src/interfaces/IExttload.sol

/// @notice Interface for functions to access any transient storage slot in a contract
interface IExttload {
    /// @notice Called by external contracts to access transient storage of the contract
    /// @param slot Key of slot to tload
    /// @return value The value of the slot as bytes32
    function exttload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access sparse transient pool state
    /// @param slots List of slots to tload
    /// @return values List of loaded values
    function exttload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}

// node_modules/@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol

/// @notice Interface for the callback executed when an address unlocks the pool manager
interface IUnlockCallback {
    /// @notice Called by the pool manager on `msg.sender` when the manager is unlocked
    /// @param data The data that was passed to the call to unlock
    /// @return Any data that you want to be returned from the unlock call
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}

// node_modules/@uniswap/v4-core/src/libraries/ParseBytes.sol

/// @notice Parses bytes returned from hooks and the byte selector used to check return selectors from hooks.
/// @dev parseSelector also is used to parse the expected selector
/// For parsing hook returns, note that all hooks return either bytes4 or (bytes4, 32-byte-delta) or (bytes4, 32-byte-delta, uint24).
library ParseBytes {
    function parseSelector(bytes memory result) internal pure returns (bytes4 selector) {
        // equivalent: (selector,) = abi.decode(result, (bytes4, int256));
        assembly ("memory-safe") {
            selector := mload(add(result, 0x20))
        }
    }

    function parseFee(bytes memory result) internal pure returns (uint24 lpFee) {
        // equivalent: (,, lpFee) = abi.decode(result, (bytes4, int256, uint24));
        assembly ("memory-safe") {
            lpFee := mload(add(result, 0x60))
        }
    }

    function parseReturnDelta(bytes memory result) internal pure returns (int256 hookReturn) {
        // equivalent: (, hookReturnDelta) = abi.decode(result, (bytes4, int256));
        assembly ("memory-safe") {
            hookReturn := mload(add(result, 0x40))
        }
    }
}

// node_modules/@openzeppelin/contracts/utils/TransientSlot.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/TransientSlot.sol)
// This file was procedurally generated from scripts/generate/templates/TransientSlot.js.

/**
 * @dev Library for reading and writing value-types to specific transient storage slots.
 *
 * Transient slots are often used to store temporary values that are removed after the current transaction.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 *  * Example reading and writing values using transient storage:
 * ```solidity
 * contract Lock {
 *     using TransientSlot for *;
 *
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _LOCK_SLOT = 0xf4678858b2b588224636b8522b729e7722d32fc491da849ed75b3fdf3c84f542;
 *
 *     modifier locked() {
 *         require(!_LOCK_SLOT.asBoolean().tload());
 *
 *         _LOCK_SLOT.asBoolean().tstore(true);
 *         _;
 *         _LOCK_SLOT.asBoolean().tstore(false);
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library TransientSlot {
    /**
     * @dev UDVT that represents a slot holding an address.
     */
    type AddressSlot is bytes32;

    /**
     * @dev Cast an arbitrary slot to a AddressSlot.
     */
    function asAddress(bytes32 slot) internal pure returns (AddressSlot) {
        return AddressSlot.wrap(slot);
    }

    /**
     * @dev UDVT that represents a slot holding a bool.
     */
    type BooleanSlot is bytes32;

    /**
     * @dev Cast an arbitrary slot to a BooleanSlot.
     */
    function asBoolean(bytes32 slot) internal pure returns (BooleanSlot) {
        return BooleanSlot.wrap(slot);
    }

    /**
     * @dev UDVT that represents a slot holding a bytes32.
     */
    type Bytes32Slot is bytes32;

    /**
     * @dev Cast an arbitrary slot to a Bytes32Slot.
     */
    function asBytes32(bytes32 slot) internal pure returns (Bytes32Slot) {
        return Bytes32Slot.wrap(slot);
    }

    /**
     * @dev UDVT that represents a slot holding a uint256.
     */
    type Uint256Slot is bytes32;

    /**
     * @dev Cast an arbitrary slot to a Uint256Slot.
     */
    function asUint256(bytes32 slot) internal pure returns (Uint256Slot) {
        return Uint256Slot.wrap(slot);
    }

    /**
     * @dev UDVT that represents a slot holding a int256.
     */
    type Int256Slot is bytes32;

    /**
     * @dev Cast an arbitrary slot to a Int256Slot.
     */
    function asInt256(bytes32 slot) internal pure returns (Int256Slot) {
        return Int256Slot.wrap(slot);
    }

    /**
     * @dev Load the value held at location `slot` in transient storage.
     */
    function tload(AddressSlot slot) internal view returns (address value) {
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /**
     * @dev Store `value` at location `slot` in transient storage.
     */
    function tstore(AddressSlot slot, address value) internal {
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    /**
     * @dev Load the value held at location `slot` in transient storage.
     */
    function tload(BooleanSlot slot) internal view returns (bool value) {
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /**
     * @dev Store `value` at location `slot` in transient storage.
     */
    function tstore(BooleanSlot slot, bool value) internal {
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    /**
     * @dev Load the value held at location `slot` in transient storage.
     */
    function tload(Bytes32Slot slot) internal view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /**
     * @dev Store `value` at location `slot` in transient storage.
     */
    function tstore(Bytes32Slot slot, bytes32 value) internal {
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    /**
     * @dev Load the value held at location `slot` in transient storage.
     */
    function tload(Uint256Slot slot) internal view returns (uint256 value) {
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /**
     * @dev Store `value` at location `slot` in transient storage.
     */
    function tstore(Uint256Slot slot, uint256 value) internal {
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    /**
     * @dev Load the value held at location `slot` in transient storage.
     */
    function tload(Int256Slot slot) internal view returns (int256 value) {
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /**
     * @dev Store `value` at location `slot` in transient storage.
     */
    function tstore(Int256Slot slot, int256 value) internal {
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }
}

// node_modules/@zama-fhe/oracle-solidity/address/ZamaOracleAddress.sol

address constant SepoliaZamaOracleAddress = 0xa02Cda4Ca3a71D7C46997716F4283aa851C28812;

// node_modules/@openzeppelin/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// node_modules/@openzeppelin/contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

// node_modules/@openzeppelin/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

// node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// node_modules/@fhevm/solidity/lib/Impl.sol

/**
 * @title   CoprocessorConfig
 * @notice  This struct contains all addresses of core contracts, which are needed in a typical dApp.
 */
struct CoprocessorConfig {
    address ACLAddress;
    address CoprocessorAddress;
    address DecryptionOracleAddress;
    address KMSVerifierAddress;
}

/**
 * @title   DecryptionRequests
 * @notice  This struct contains the internal counter for requestIDs generated by the dapp,
 *          and the mapping from internal requestIDs to list of handles requested for decryption.
 */
struct DecryptionRequests {
    uint256 counterRequest;
    mapping(uint256 => bytes32[]) requestedHandles;
}

/**
 * @title   IFHEVMExecutor
 * @notice  This interface contains all functions to conduct FHE operations.
 */
interface IFHEVMExecutor {
    /**
     * @notice              Computes fheAdd operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheAdd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheSub operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheSub(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheMul operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheMul(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheDiv operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheDiv(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheRem operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheRem(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheBitAnd operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheBitAnd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheBitOr operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheBitOr(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheBitXor operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheBitXor(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheShl operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheShl(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheShr operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheShr(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheRotl operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheRotl(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheRotr operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheRotr(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheEq operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheEq(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheNe operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheNe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheGe operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheGe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheGt operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheGt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheLe operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheLe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheLt operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheLt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheMin operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheMin(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheMax operation.
     * @param lhs           LHS.
     * @param rhs           RHS.
     * @param scalarByte    Scalar byte.
     * @return result       Result.
     */
    function fheMax(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);

    /**
     * @notice              Computes fheNeg operation.
     * @param ct            Ct
     * @return result       Result.
     */
    function fheNeg(bytes32 ct) external returns (bytes32 result);

    /**
     * @notice              Computes fheNot operation.
     * @param ct            Ct
     * @return result       Result.
     */
    function fheNot(bytes32 ct) external returns (bytes32 result);
    /**
     * @notice                Verifies the ciphertext.
     * @param inputHandle     Input handle.
     * @param callerAddress   Address of the caller.
     * @param inputProof      Input proof.
     * @param inputType       Input type.
     * @return result         Result.
     */
    function verifyCiphertext(
        bytes32 inputHandle,
        address callerAddress,
        bytes memory inputProof,
        FheType inputType
    ) external returns (bytes32 result);

    /**
     * @notice          Performs the casting to a target type.
     * @param ct        Value to cast.
     * @param toType    Target type.
     * @return result   Result value of the target type.
     */
    function cast(bytes32 ct, FheType toType) external returns (bytes32 result);

    /**
     * @notice          Does trivial encryption.
     * @param ct        Value to encrypt.
     * @param toType    Target type.
     * @return result   Result value of the target type.
     */
    function trivialEncrypt(uint256 ct, FheType toType) external returns (bytes32 result);

    /**
     * @notice              Computes FHEIfThenElse operation.
     * @param control       Control value.
     * @param ifTrue        If true.
     * @param ifFalse       If false.
     * @return result       Result.
     */
    function fheIfThenElse(bytes32 control, bytes32 ifTrue, bytes32 ifFalse) external returns (bytes32 result);

    /**
     * @notice              Computes FHERand operation.
     * @param randType      Type for the random result.
     * @return result       Result.
     */
    function fheRand(FheType randType) external returns (bytes32 result);

    /**
     * @notice              Computes FHERandBounded operation.
     * @param upperBound    Upper bound value.
     * @param randType      Type for the random result.
     * @return result       Result.
     */
    function fheRandBounded(uint256 upperBound, FheType randType) external returns (bytes32 result);

    /**
     * @notice                      Returns the address of the InputVerifier contract used by the coprocessor.
     * @return inputVerifierAddress Address of the InputVerifier.
     */
    function getInputVerifierAddress() external view returns (address);
}

/**
 * @title   IACL.
 * @notice  This interface contains all functions that are used to conduct operations
 *          with the ACL contract.
 */
interface IACL {
    /**
     * @notice              Allows the use of handle by address account for this transaction.
     * @dev                 The caller must be allowed to use handle for allowTransient() to succeed.
     *                      If not, allowTransient() reverts.
     *                      The Coprocessor contract can always allowTransient(), contrarily to allow().
     * @param ciphertext    Ciphertext.
     * @param account       Address of the account.
     */
    function allowTransient(bytes32 ciphertext, address account) external;

    /**
     * @notice              Allows the use of handle for the address account.
     * @dev                 The caller must be allowed to use handle for allow() to succeed. If not, allow() reverts.
     * @param handle        Handle.
     * @param account       Address of the account.
     */
    function allow(bytes32 handle, address account) external;

    /**
     * @dev This function removes the transient allowances, which could be useful for integration with
     *      Account Abstraction when bundling several UserOps calling the FHEVMExecutor Coprocessor.
     */
    function cleanTransientStorage() external;

    /**
     * @notice              Returns whether the account is allowed to use the handle, either due to
     *                      allowTransient() or allow().
     * @param handle        Handle.
     * @param account       Address of the account.
     * @return isAllowed    Whether the account can access the handle.
     */
    function isAllowed(bytes32 handle, address account) external view returns (bool);

    /**
     * @notice              Allows a list of handles to be decrypted.
     * @param handlesList   List of handles.
     */
    function allowForDecryption(bytes32[] memory handlesList) external;

    /**
     * @notice                  Returns wether a handle is allowed to be publicly decrypted.
     * @param handle            Handle.
     * @return isDecryptable    Whether the handle can be publicly decrypted.
     */
    function isAllowedForDecryption(bytes32 handle) external view returns (bool);
}

/**
 * @title IInputVerifier
 * @notice This interface contains the only function required from InputVerifier.
 */
interface IInputVerifier {
    /**
     * @dev This function removes the transient allowances, which could be useful for integration with
     *      Account Abstraction when bundling several UserOps calling the FHEVMExecutor Coprocessor.
     */
    function cleanTransientStorage() external;
}

/**
 * @title   Impl
 * @notice  This library is the core implementation for computing FHE operations (e.g. add, sub, xor).
 */
library Impl {
    /// keccak256(abi.encode(uint256(keccak256("confidential.storage.config")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CoprocessorConfigLocation =
        0x9e7b61f58c47dc699ac88507c4f5bb9f121c03808c5676a8078fe583e4649700;

    /// keccak256(abi.encode(uint256(keccak256("confidential.storage.decryptionRequests")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant DecryptionRequestsStorageLocation =
        0x878245876662ba28a480c5ea71726db859fb50222b0a3d7cbbc21cfa336faf00;

    /**
     * @dev Returns the Coprocessor config.
     */
    function getCoprocessorConfig() internal pure returns (CoprocessorConfig storage $) {
        assembly {
            $.slot := CoprocessorConfigLocation
        }
    }

    /**
     * @dev Returns the DecryptionRequests storage struct.
     */
    function getDecryptionRequests() internal pure returns (DecryptionRequests storage $) {
        assembly {
            $.slot := DecryptionRequestsStorageLocation
        }
    }

    /**
     * @notice                  Sets the coprocessor addresses.
     * @param coprocessorConfig Coprocessor config struct that contains contract addresses.
     */
    function setCoprocessor(CoprocessorConfig memory coprocessorConfig) internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        $.ACLAddress = coprocessorConfig.ACLAddress;
        $.CoprocessorAddress = coprocessorConfig.CoprocessorAddress;
        $.DecryptionOracleAddress = coprocessorConfig.DecryptionOracleAddress;
        $.KMSVerifierAddress = coprocessorConfig.KMSVerifierAddress;
    }

    function add(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheAdd(lhs, rhs, scalarByte);
    }

    function sub(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheSub(lhs, rhs, scalarByte);
    }

    function mul(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheMul(lhs, rhs, scalarByte);
    }

    function div(bytes32 lhs, bytes32 rhs) internal returns (bytes32 result) {
        bytes1 scalarByte = 0x01;
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheDiv(lhs, rhs, scalarByte);
    }

    function rem(bytes32 lhs, bytes32 rhs) internal returns (bytes32 result) {
        bytes1 scalarByte = 0x01;
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheRem(lhs, rhs, scalarByte);
    }

    function and(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheBitAnd(lhs, rhs, scalarByte);
    }

    function or(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheBitOr(lhs, rhs, scalarByte);
    }

    function xor(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheBitXor(lhs, rhs, scalarByte);
    }

    function shl(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheShl(lhs, rhs, scalarByte);
    }

    function shr(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheShr(lhs, rhs, scalarByte);
    }

    function rotl(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheRotl(lhs, rhs, scalarByte);
    }

    function rotr(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheRotr(lhs, rhs, scalarByte);
    }

    function eq(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheEq(lhs, rhs, scalarByte);
    }

    function ne(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheNe(lhs, rhs, scalarByte);
    }

    function ge(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheGe(lhs, rhs, scalarByte);
    }

    function gt(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheGt(lhs, rhs, scalarByte);
    }

    function le(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheLe(lhs, rhs, scalarByte);
    }

    function lt(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheLt(lhs, rhs, scalarByte);
    }

    function min(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheMin(lhs, rhs, scalarByte);
    }

    function max(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheMax(lhs, rhs, scalarByte);
    }

    function neg(bytes32 ct) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheNeg(ct);
    }

    function not(bytes32 ct) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheNot(ct);
    }

    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(bytes32 control, bytes32 ifTrue, bytes32 ifFalse) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheIfThenElse(control, ifTrue, ifFalse);
    }

    /**
     * @notice              Verifies the ciphertext (FHEVMExecutor) and allows transient (ACL).
     * @param inputHandle   Input handle.
     * @param inputProof    Input proof.
     * @param toType        Input type.
     * @return result       Result.
     */
    function verify(bytes32 inputHandle, bytes memory inputProof, FheType toType) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).verifyCiphertext(inputHandle, msg.sender, inputProof, toType);
        IACL($.ACLAddress).allowTransient(result, msg.sender);
    }

    /**
     * @notice            Performs the casting to a target type.
     * @param ciphertext  Ciphertext to cast.
     * @param toType      Target type.
     * @return result     Result value of the target type.
     */
    function cast(bytes32 ciphertext, FheType toType) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).cast(ciphertext, toType);
    }

    /**
     * @notice          Does trivial encryption.
     * @param value     Value to encrypt.
     * @param toType    Target type.
     * @return result   Result value of the target type.
     */
    function trivialEncrypt(uint256 value, FheType toType) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).trivialEncrypt(value, toType);
    }

    function rand(FheType randType) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheRand(randType);
    }

    function randBounded(uint256 upperBound, FheType randType) internal returns (bytes32 result) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        result = IFHEVMExecutor($.CoprocessorAddress).fheRandBounded(upperBound, randType);
    }

    /**
     * @notice              Allows the use of handle by address account for this transaction.
     * @dev                 The caller must be allowed to use handle for allowTransient() to succeed.
     *                      If not, allowTransient() reverts.
     *                      The Coprocessor contract can always allowTransient(), contrarily to allow().
     * @param handle        Handle.
     * @param account       Address of the account.
     */
    function allowTransient(bytes32 handle, address account) internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        IACL($.ACLAddress).allowTransient(handle, account);
    }

    /**
     * @notice              Allows the use of handle for the address account.
     * @dev                 The caller must be allowed to use handle for allow() to succeed. If not, allow() reverts.
     * @param handle        Handle.
     * @param account       Address of the account.
     */
    function allow(bytes32 handle, address account) internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        IACL($.ACLAddress).allow(handle, account);
    }

    /**
     * @notice              Allows the handle to be publicly decryptable.
     * @dev                 The caller must be allowed to use handle for makePubliclyDecryptable() to succeed.
     *                      If not, makePubliclyDecryptable() reverts.
     * @param handle        Handle.
     */
    function makePubliclyDecryptable(bytes32 handle) internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        bytes32[] memory handleArray = new bytes32[](1);
        handleArray[0] = handle;
        IACL($.ACLAddress).allowForDecryption(handleArray);
    }

    /**
     * @dev This function removes the transient allowances in the ACL, which could be useful for integration
     *      with Account Abstraction when bundling several UserOps calling the FHEVMExecutor Coprocessor.
     */
    function cleanTransientStorageACL() internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        IACL($.ACLAddress).cleanTransientStorage();
    }

    /**
     * @dev This function removes the transient proofs in the InputVerifier, which could be useful for integration
     *      with Account Abstraction when bundling several UserOps calling the FHEVMExecutor Coprocessor.
     */
    function cleanTransientStorageInputVerifier() internal {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        address inputVerifierAddress = IFHEVMExecutor($.CoprocessorAddress).getInputVerifierAddress();
        IInputVerifier(inputVerifierAddress).cleanTransientStorage();
    }

    /**
     * @notice              Returns whether the account is allowed to use the handle, either due to
     *                      allowTransient() or allow().
     * @param handle        Handle.
     * @param account       Address of the account.
     * @return isAllowed    Whether the account can access the handle.
     */
    function isAllowed(bytes32 handle, address account) internal view returns (bool) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        return IACL($.ACLAddress).isAllowed(handle, account);
    }

    /**
     * @notice              Returns whether the handle is allowed to be publicly decrypted.
     * @param handle        Handle.
     * @return isAllowed    Whether the handle can be publicly decrypted.
     */
    function isPubliclyDecryptable(bytes32 handle) internal view returns (bool) {
        CoprocessorConfig storage $ = getCoprocessorConfig();
        return IACL($.ACLAddress).isAllowedForDecryption(handle);
    }
}

// node_modules/@uniswap/v4-core/src/libraries/LPFeeLibrary.sol

/// @notice Library of helper functions for a pools LP fee
library LPFeeLibrary {
    using LPFeeLibrary for uint24;
    using CustomRevert for bytes4;

    /// @notice Thrown when the static or dynamic fee on a pool exceeds 100%.
    error LPFeeTooLarge(uint24 fee);

    /// @notice An lp fee of exactly 0b1000000... signals a dynamic fee pool. This isn't a valid static fee as it is > MAX_LP_FEE
    uint24 public constant DYNAMIC_FEE_FLAG = 0x800000;

    /// @notice the second bit of the fee returned by beforeSwap is used to signal if the stored LP fee should be overridden in this swap
    // only dynamic-fee pools can return a fee via the beforeSwap hook
    uint24 public constant OVERRIDE_FEE_FLAG = 0x400000;

    /// @notice mask to remove the override fee flag from a fee returned by the beforeSwaphook
    uint24 public constant REMOVE_OVERRIDE_MASK = 0xBFFFFF;

    /// @notice the lp fee is represented in hundredths of a bip, so the max is 100%
    uint24 public constant MAX_LP_FEE = 1000000;

    /// @notice returns true if a pool's LP fee signals that the pool has a dynamic fee
    /// @param self The fee to check
    /// @return bool True of the fee is dynamic
    function isDynamicFee(uint24 self) internal pure returns (bool) {
        return self == DYNAMIC_FEE_FLAG;
    }

    /// @notice returns true if an LP fee is valid, aka not above the maximum permitted fee
    /// @param self The fee to check
    /// @return bool True of the fee is valid
    function isValid(uint24 self) internal pure returns (bool) {
        return self <= MAX_LP_FEE;
    }

    /// @notice validates whether an LP fee is larger than the maximum, and reverts if invalid
    /// @param self The fee to validate
    function validate(uint24 self) internal pure {
        if (!self.isValid()) LPFeeTooLarge.selector.revertWith(self);
    }

    /// @notice gets and validates the initial LP fee for a pool. Dynamic fee pools have an initial fee of 0.
    /// @dev if a dynamic fee pool wants a non-0 initial fee, it should call `updateDynamicLPFee` in the afterInitialize hook
    /// @param self The fee to get the initial LP from
    /// @return initialFee 0 if the fee is dynamic, otherwise the fee (if valid)
    function getInitialLPFee(uint24 self) internal pure returns (uint24) {
        // the initial fee for a dynamic fee pool is 0
        if (self.isDynamicFee()) return 0;
        self.validate();
        return self;
    }

    /// @notice returns true if the fee has the override flag set (2nd highest bit of the uint24)
    /// @param self The fee to check
    /// @return bool True of the fee has the override flag set
    function isOverride(uint24 self) internal pure returns (bool) {
        return self & OVERRIDE_FEE_FLAG != 0;
    }

    /// @notice returns a fee with the override flag removed
    /// @param self The fee to remove the override flag from
    /// @return fee The fee without the override flag set
    function removeOverrideFlag(uint24 self) internal pure returns (uint24) {
        return self & REMOVE_OVERRIDE_MASK;
    }

    /// @notice Removes the override flag and validates the fee (reverts if the fee is too large)
    /// @param self The fee to remove the override flag from, and then validate
    /// @return fee The fee without the override flag set (if valid)
    function removeOverrideFlagAndValidate(uint24 self) internal pure returns (uint24 fee) {
        fee = self.removeOverrideFlag();
        fee.validate();
    }
}

// node_modules/@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/ReentrancyGuardTransient.sol)

/**
 * @dev Variant of {ReentrancyGuard} that uses transient storage.
 *
 * NOTE: This variant only works on networks where EIP-1153 is available.
 *
 * _Available since v5.1._
 */
abstract contract ReentrancyGuardTransient {
    using TransientSlot for *;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, REENTRANCY_GUARD_STORAGE.asBoolean().tload() will be false
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        REENTRANCY_GUARD_STORAGE.asBoolean().tstore(true);
    }

    function _nonReentrantAfter() private {
        REENTRANCY_GUARD_STORAGE.asBoolean().tstore(false);
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return REENTRANCY_GUARD_STORAGE.asBoolean().tload();
    }
}

// node_modules/@uniswap/v4-core/src/libraries/SafeCast.sol

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    using CustomRevert for bytes4;

    error SafeCastOverflow();

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint160
    function toUint160(uint256 x) internal pure returns (uint160 y) {
        y = uint160(x);
        if (y != x) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint128
    function toUint128(uint256 x) internal pure returns (uint128 y) {
        y = uint128(x);
        if (x != y) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a int128 to a uint128, revert on overflow or underflow
    /// @param x The int128 to be casted
    /// @return y The casted integer, now type uint128
    function toUint128(int128 x) internal pure returns (uint128 y) {
        if (x < 0) SafeCastOverflow.selector.revertWith();
        y = uint128(x);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param x The int256 to be downcasted
    /// @return y The downcasted integer, now type int128
    function toInt128(int256 x) internal pure returns (int128 y) {
        y = int128(x);
        if (y != x) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param x The uint256 to be casted
    /// @return y The casted integer, now type int256
    function toInt256(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        if (y < 0) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a int128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return The downcasted integer, now type int128
    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) SafeCastOverflow.selector.revertWith();
        return int128(int256(x));
    }
}

// node_modules/@uniswap/v4-core/src/types/BalanceDelta.sol

/// @dev Two `int128` values packed into a single `int256` where the upper 128 bits represent the amount0
/// and the lower 128 bits represent the amount1.
type BalanceDelta is int256;

using {add as +, sub as -, eq as ==, neq as !=} for BalanceDelta global;
using BalanceDeltaLibrary for BalanceDelta global;
using SafeCast for int256;

function toBalanceDelta(int128 _amount0, int128 _amount1) pure returns (BalanceDelta balanceDelta) {
    assembly ("memory-safe") {
        balanceDelta := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
    }
}

function add(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := add(a0, b0)
        res1 := add(a1, b1)
    }
    return toBalanceDelta(res0.toInt128(), res1.toInt128());
}

function sub(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := sub(a0, b0)
        res1 := sub(a1, b1)
    }
    return toBalanceDelta(res0.toInt128(), res1.toInt128());
}

function eq(BalanceDelta a, BalanceDelta b) pure returns (bool) {
    return BalanceDelta.unwrap(a) == BalanceDelta.unwrap(b);
}

function neq(BalanceDelta a, BalanceDelta b) pure returns (bool) {
    return BalanceDelta.unwrap(a) != BalanceDelta.unwrap(b);
}

/// @notice Library for getting the amount0 and amount1 deltas from the BalanceDelta type
library BalanceDeltaLibrary {
    /// @notice A BalanceDelta of 0
    BalanceDelta public constant ZERO_DELTA = BalanceDelta.wrap(0);

    function amount0(BalanceDelta balanceDelta) internal pure returns (int128 _amount0) {
        assembly ("memory-safe") {
            _amount0 := sar(128, balanceDelta)
        }
    }

    function amount1(BalanceDelta balanceDelta) internal pure returns (int128 _amount1) {
        assembly ("memory-safe") {
            _amount1 := signextend(15, balanceDelta)
        }
    }
}

// node_modules/@uniswap/v4-core/src/types/Currency.sol

type Currency is address;

using {greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=, equals as ==} for Currency global;
using CurrencyLibrary for Currency global;

function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function greaterThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) > Currency.unwrap(other);
}

function lessThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) < Currency.unwrap(other);
}

function greaterThanOrEqualTo(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) >= Currency.unwrap(other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library CurrencyLibrary {
    /// @notice Additional context for ERC-7751 wrapped error when a native transfer fails
    error NativeTransferFailed();

    /// @notice Additional context for ERC-7751 wrapped error when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice A constant to represent the native currency
    Currency public constant ADDRESS_ZERO = Currency.wrap(address(0));

    function transfer(Currency currency, address to, uint256 amount) internal {
        // altered from https://github.com/transmissions11/solmate/blob/44a9963d4c78111f77caa0e65d677b8b46d6f2e6/src/utils/SafeTransferLib.sol
        // modified custom error selectors

        bool success;
        if (currency.isAddressZero()) {
            assembly ("memory-safe") {
                // Transfer the ETH and revert if it fails.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            // revert with NativeTransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(to, bytes4(0), NativeTransferFailed.selector);
            }
        } else {
            assembly ("memory-safe") {
                // Get a pointer to some free memory.
                let fmp := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(fmp, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(fmp, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(fmp, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the or() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        call(gas(), currency, 0, fmp, 68, 0, 32)
                    )

                // Now clean the memory we used
                mstore(fmp, 0) // 4 byte `selector` and 28 bytes of `to` were stored here
                mstore(add(fmp, 0x20), 0) // 4 bytes of `to` and 28 bytes of `amount` were stored here
                mstore(add(fmp, 0x40), 0) // 4 bytes of `amount` were stored here
            }
            // revert with ERC20TransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(
                    Currency.unwrap(currency), IERC20Minimal.transfer.selector, ERC20TransferFailed.selector
                );
            }
        }
    }

    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        if (currency.isAddressZero()) {
            return address(this).balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(address(this));
        }
    }

    function balanceOf(Currency currency, address owner) internal view returns (uint256) {
        if (currency.isAddressZero()) {
            return owner.balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(owner);
        }
    }

    function isAddressZero(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(ADDRESS_ZERO);
    }

    function toId(Currency currency) internal pure returns (uint256) {
        return uint160(Currency.unwrap(currency));
    }

    // If the upper 12 bytes are non-zero, they will be zero-ed out
    // Therefore, fromId() and toId() are not inverses of each other
    function fromId(uint256 id) internal pure returns (Currency) {
        return Currency.wrap(address(uint160(id)));
    }
}

// node_modules/@uniswap/v4-core/src/libraries/TickMath.sol

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    using CustomRevert for bytes4;

    /// @notice Thrown when the tick passed to #getSqrtPriceAtTick is not between MIN_TICK and MAX_TICK
    error InvalidTick(int24 tick);
    /// @notice Thrown when the price passed to #getTickAtSqrtPrice does not correspond to a price between MIN_TICK and MAX_TICK
    error InvalidSqrtPrice(uint160 sqrtPriceX96);

    /// @dev The minimum tick that may be passed to #getSqrtPriceAtTick computed from log base 1.0001 of 2**-128
    /// @dev If ever MIN_TICK and MAX_TICK are not centered around 0, the absTick logic in getSqrtPriceAtTick cannot be used
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtPriceAtTick computed from log base 1.0001 of 2**128
    /// @dev If ever MIN_TICK and MAX_TICK are not centered around 0, the absTick logic in getSqrtPriceAtTick cannot be used
    int24 internal constant MAX_TICK = 887272;

    /// @dev The minimum tick spacing value drawn from the range of type int16 that is greater than 0, i.e. min from the range [1, 32767]
    int24 internal constant MIN_TICK_SPACING = 1;
    /// @dev The maximum tick spacing value drawn from the range of type int16, i.e. max from the range [1, 32767]
    int24 internal constant MAX_TICK_SPACING = type(int16).max;

    /// @dev The minimum value that can be returned from #getSqrtPriceAtTick. Equivalent to getSqrtPriceAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtPriceAtTick. Equivalent to getSqrtPriceAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;
    /// @dev A threshold used for optimized bounds check, equals `MAX_SQRT_PRICE - MIN_SQRT_PRICE - 1`
    uint160 internal constant MAX_SQRT_PRICE_MINUS_MIN_SQRT_PRICE_MINUS_ONE =
        1461446703485210103287273052203988822378723970342 - 4295128739 - 1;

    /// @notice Given a tickSpacing, compute the maximum usable tick
    function maxUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Given a tickSpacing, compute the minimum usable tick
    function minUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MIN_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the price of the two assets (currency1/currency0)
    /// at the given tick
    function getSqrtPriceAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick;
            assembly ("memory-safe") {
                tick := signextend(2, tick)
                // mask = 0 if tick >= 0 else -1 (all 1s)
                let mask := sar(255, tick)
                // if tick >= 0, |tick| = tick = 0 ^ tick
                // if tick < 0, |tick| = ~~|tick| = ~(-|tick| - 1) = ~(tick - 1) = (-1) ^ (tick - 1)
                // either way, |tick| = mask ^ (tick + mask)
                absTick := xor(mask, add(mask, tick))
            }

            if (absTick > uint256(int256(MAX_TICK))) InvalidTick.selector.revertWith(tick);

            // The tick is decomposed into bits, and for each bit with index i that is set, the product of 1/sqrt(1.0001^(2^i))
            // is calculated (using Q128.128). The constants used for this calculation are rounded to the nearest integer

            // Equivalent to:
            //     price = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            //     or price = int(2**128 / sqrt(1.0001)) if (absTick & 0x1) else 1 << 128
            uint256 price;
            assembly ("memory-safe") {
                price := xor(shl(128, 1), mul(xor(shl(128, 1), 0xfffcb933bd6fad37aa2d162d1a594001), and(absTick, 0x1)))
            }
            if (absTick & 0x2 != 0) price = (price * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) price = (price * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) price = (price * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) price = (price * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) price = (price * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) price = (price * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) price = (price * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) price = (price * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) price = (price * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) price = (price * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) price = (price * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) price = (price * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) price = (price * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) price = (price * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) price = (price * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) price = (price * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) price = (price * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) price = (price * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) price = (price * 0x48a170391f7dc42444e8fa2) >> 128;

            assembly ("memory-safe") {
                // if (tick > 0) price = type(uint256).max / price;
                if sgt(tick, 0) { price := div(not(0), price) }

                // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
                // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
                // we round up in the division so getTickAtSqrtPrice of the output price is always consistent
                // `sub(shl(32, 1), 1)` is `type(uint32).max`
                // `price + type(uint32).max` will not overflow because `price` fits in 192 bits
                sqrtPriceX96 := shr(32, add(price, sub(shl(32, 1), 1)))
            }
        }
    }

    /// @notice Calculates the greatest tick value such that getSqrtPriceAtTick(tick) <= sqrtPriceX96
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_PRICE, as MIN_SQRT_PRICE is the lowest value getSqrtPriceAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt price for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the getSqrtPriceAtTick(tick) is less than or equal to the input sqrtPriceX96
    function getTickAtSqrtPrice(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // Equivalent: if (sqrtPriceX96 < MIN_SQRT_PRICE || sqrtPriceX96 >= MAX_SQRT_PRICE) revert InvalidSqrtPrice();
            // second inequality must be >= because the price can never reach the price at the max tick
            // if sqrtPriceX96 < MIN_SQRT_PRICE, the `sub` underflows and `gt` is true
            // if sqrtPriceX96 >= MAX_SQRT_PRICE, sqrtPriceX96 - MIN_SQRT_PRICE > MAX_SQRT_PRICE - MIN_SQRT_PRICE - 1
            if ((sqrtPriceX96 - MIN_SQRT_PRICE) > MAX_SQRT_PRICE_MINUS_MIN_SQRT_PRICE_MINUS_ONE) {
                InvalidSqrtPrice.selector.revertWith(sqrtPriceX96);
            }

            uint256 price = uint256(sqrtPriceX96) << 32;

            uint256 r = price;
            uint256 msb = BitMath.mostSignificantBit(r);

            if (msb >= 128) r = price >> (msb - 127);
            else r = price << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly ("memory-safe") {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // Q22.128 number

            // Magic number represents the ceiling of the maximum value of the error when approximating log_sqrt10001(x)
            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);

            // Magic number represents the minimum value of the error when approximating log_sqrt10001(x), when
            // sqrtPrice is from the range (2^-64, 2^64). This is safe as MIN_SQRT_PRICE is more than 2^-64. If MIN_SQRT_PRICE
            // is changed, this may need to be changed too
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtPriceAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// node_modules/@fhevm/solidity/lib/FHE.sol

/**
 * @title IKMSVerifier
 * @notice This interface contains the only function required from KMSVerifier.
 */
interface IKMSVerifier {
    function verifyDecryptionEIP712KMSSignatures(
        bytes32[] memory handlesList,
        bytes memory decryptedResult,
        bytes memory decryptionProof
    ) external returns (bool);
}

/**
 * @title IDecryptionOracle
 * @notice This interface contains the only function required from DecryptionOracle.
 */
interface IDecryptionOracle {
    function requestDecryption(
        uint256 requestID,
        bytes32[] calldata ctsHandles,
        bytes4 callbackSelector
    ) external payable;
}

/**
 * @title   FHE
 * @notice  This library is the interaction point for all smart contract developers
 *          that interact with the FHEVM protocol.
 */
library FHE {
    /// @notice Returned if some handles were already saved for corresponding ID.
    error HandlesAlreadySavedForRequestID();

    /// @notice Returned if there was not handle found for the requested ID.
    error NoHandleFoundForRequestID();

    /// @notice Returned if the returned KMS signatures are not valid.
    error InvalidKMSSignatures();

    /// @notice This event is emitted when requested decryption has been fulfilled.
    event DecryptionFulfilled(uint256 indexed requestID);

    /**
     * @notice                  Sets the coprocessor addresses.
     * @param coprocessorConfig Coprocessor config struct that contains contract addresses.
     */
    function setCoprocessor(CoprocessorConfig memory coprocessorConfig) internal {
        Impl.setCoprocessor(coprocessorConfig);
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(ebool v) internal pure returns (bool) {
        return ebool.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint8 v) internal pure returns (bool) {
        return euint8.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint16 v) internal pure returns (bool) {
        return euint16.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint32 v) internal pure returns (bool) {
        return euint32.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint64 v) internal pure returns (bool) {
        return euint64.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint128 v) internal pure returns (bool) {
        return euint128.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(eaddress v) internal pure returns (bool) {
        return eaddress.unwrap(v) != 0;
    }

    /**
     * @dev Returns true if the encrypted integer is initialized and false otherwise.
     */
    function isInitialized(euint256 v) internal pure returns (bool) {
        return euint256.unwrap(v) != 0;
    }

    /**
     * @dev Evaluates and(ebool a, ebool b) and returns the result.
     */
    function and(ebool a, ebool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.and(ebool.unwrap(a), ebool.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(ebool a, ebool b) and returns the result.
     */
    function or(ebool a, ebool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.or(ebool.unwrap(a), ebool.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(ebool a, ebool b) and returns the result.
     */
    function xor(ebool a, ebool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.xor(ebool.unwrap(a), ebool.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(ebool a, ebool b) and returns the result.
     */
    function eq(ebool a, ebool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.eq(ebool.unwrap(a), ebool.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(ebool a, ebool b) and returns the result.
     */
    function ne(ebool a, ebool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.ne(ebool.unwrap(a), ebool.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint8 a, euint8 b)  and returns the result.
     */
    function add(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.add(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint8 a, euint8 b)  and returns the result.
     */
    function sub(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.sub(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, euint8 b)  and returns the result.
     */
    function mul(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.mul(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint8 b)  and returns the result.
     */
    function and(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.and(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint8 b)  and returns the result.
     */
    function or(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.or(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint8 b)  and returns the result.
     */
    function xor(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.xor(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint8 b)  and returns the result.
     */
    function eq(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint8 b)  and returns the result.
     */
    function ne(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint8 a, euint8 b)  and returns the result.
     */
    function ge(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint8 a, euint8 b)  and returns the result.
     */
    function gt(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint8 a, euint8 b)  and returns the result.
     */
    function le(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint8 a, euint8 b)  and returns the result.
     */
    function lt(euint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint8 a, euint8 b)  and returns the result.
     */
    function min(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.min(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint8 a, euint8 b)  and returns the result.
     */
    function max(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.max(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint8 a, euint16 b)  and returns the result.
     */
    function add(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.add(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint8 a, euint16 b)  and returns the result.
     */
    function sub(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.sub(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, euint16 b)  and returns the result.
     */
    function mul(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.mul(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint16 b)  and returns the result.
     */
    function and(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.and(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint16 b)  and returns the result.
     */
    function or(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.or(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint16 b)  and returns the result.
     */
    function xor(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.xor(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint16 b)  and returns the result.
     */
    function eq(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint16 b)  and returns the result.
     */
    function ne(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint8 a, euint16 b)  and returns the result.
     */
    function ge(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint8 a, euint16 b)  and returns the result.
     */
    function gt(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint8 a, euint16 b)  and returns the result.
     */
    function le(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint8 a, euint16 b)  and returns the result.
     */
    function lt(euint8 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint8 a, euint16 b)  and returns the result.
     */
    function min(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.min(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint8 a, euint16 b)  and returns the result.
     */
    function max(euint8 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.max(euint16.unwrap(asEuint16(a)), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint8 a, euint32 b)  and returns the result.
     */
    function add(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint8 a, euint32 b)  and returns the result.
     */
    function sub(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, euint32 b)  and returns the result.
     */
    function mul(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint32 b)  and returns the result.
     */
    function and(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint32 b)  and returns the result.
     */
    function or(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint32 b)  and returns the result.
     */
    function xor(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint32 b)  and returns the result.
     */
    function eq(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint32 b)  and returns the result.
     */
    function ne(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint8 a, euint32 b)  and returns the result.
     */
    function ge(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint8 a, euint32 b)  and returns the result.
     */
    function gt(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint8 a, euint32 b)  and returns the result.
     */
    function le(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint8 a, euint32 b)  and returns the result.
     */
    function lt(euint8 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint8 a, euint32 b)  and returns the result.
     */
    function min(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint8 a, euint32 b)  and returns the result.
     */
    function max(euint8 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint8 a, euint64 b)  and returns the result.
     */
    function add(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint8 a, euint64 b)  and returns the result.
     */
    function sub(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, euint64 b)  and returns the result.
     */
    function mul(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint64 b)  and returns the result.
     */
    function and(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint64 b)  and returns the result.
     */
    function or(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint64 b)  and returns the result.
     */
    function xor(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint64 b)  and returns the result.
     */
    function eq(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint64 b)  and returns the result.
     */
    function ne(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint8 a, euint64 b)  and returns the result.
     */
    function ge(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint8 a, euint64 b)  and returns the result.
     */
    function gt(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint8 a, euint64 b)  and returns the result.
     */
    function le(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint8 a, euint64 b)  and returns the result.
     */
    function lt(euint8 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint8 a, euint64 b)  and returns the result.
     */
    function min(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint8 a, euint64 b)  and returns the result.
     */
    function max(euint8 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint8 a, euint128 b)  and returns the result.
     */
    function add(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint8 a, euint128 b)  and returns the result.
     */
    function sub(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, euint128 b)  and returns the result.
     */
    function mul(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint128 b)  and returns the result.
     */
    function and(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint128 b)  and returns the result.
     */
    function or(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint128 b)  and returns the result.
     */
    function xor(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint128 b)  and returns the result.
     */
    function eq(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint128 b)  and returns the result.
     */
    function ne(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint8 a, euint128 b)  and returns the result.
     */
    function ge(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint8 a, euint128 b)  and returns the result.
     */
    function gt(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint8 a, euint128 b)  and returns the result.
     */
    function le(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint8 a, euint128 b)  and returns the result.
     */
    function lt(euint8 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint8 a, euint128 b)  and returns the result.
     */
    function min(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint8 a, euint128 b)  and returns the result.
     */
    function max(euint8 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint8 a, euint256 b)  and returns the result.
     */
    function and(euint8 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint8 a, euint256 b)  and returns the result.
     */
    function or(euint8 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint8 a, euint256 b)  and returns the result.
     */
    function xor(euint8 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint8 a, euint256 b)  and returns the result.
     */
    function eq(euint8 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint8 a, euint256 b)  and returns the result.
     */
    function ne(euint8 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint16 a, euint8 b)  and returns the result.
     */
    function add(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.add(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates sub(euint16 a, euint8 b)  and returns the result.
     */
    function sub(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.sub(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, euint8 b)  and returns the result.
     */
    function mul(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.mul(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint8 b)  and returns the result.
     */
    function and(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.and(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint8 b)  and returns the result.
     */
    function or(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.or(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint8 b)  and returns the result.
     */
    function xor(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.xor(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint8 b)  and returns the result.
     */
    function eq(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint8 b)  and returns the result.
     */
    function ne(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates ge(euint16 a, euint8 b)  and returns the result.
     */
    function ge(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates gt(euint16 a, euint8 b)  and returns the result.
     */
    function gt(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates le(euint16 a, euint8 b)  and returns the result.
     */
    function le(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates lt(euint16 a, euint8 b)  and returns the result.
     */
    function lt(euint16 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates min(euint16 a, euint8 b)  and returns the result.
     */
    function min(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.min(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates max(euint16 a, euint8 b)  and returns the result.
     */
    function max(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.max(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates add(euint16 a, euint16 b)  and returns the result.
     */
    function add(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.add(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint16 a, euint16 b)  and returns the result.
     */
    function sub(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.sub(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, euint16 b)  and returns the result.
     */
    function mul(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.mul(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint16 b)  and returns the result.
     */
    function and(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.and(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint16 b)  and returns the result.
     */
    function or(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.or(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint16 b)  and returns the result.
     */
    function xor(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.xor(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint16 b)  and returns the result.
     */
    function eq(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint16 b)  and returns the result.
     */
    function ne(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint16 a, euint16 b)  and returns the result.
     */
    function ge(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint16 a, euint16 b)  and returns the result.
     */
    function gt(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint16 a, euint16 b)  and returns the result.
     */
    function le(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint16 a, euint16 b)  and returns the result.
     */
    function lt(euint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint16 a, euint16 b)  and returns the result.
     */
    function min(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.min(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint16 a, euint16 b)  and returns the result.
     */
    function max(euint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.max(euint16.unwrap(a), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint16 a, euint32 b)  and returns the result.
     */
    function add(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint16 a, euint32 b)  and returns the result.
     */
    function sub(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, euint32 b)  and returns the result.
     */
    function mul(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint32 b)  and returns the result.
     */
    function and(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint32 b)  and returns the result.
     */
    function or(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint32 b)  and returns the result.
     */
    function xor(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint32 b)  and returns the result.
     */
    function eq(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint32 b)  and returns the result.
     */
    function ne(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint16 a, euint32 b)  and returns the result.
     */
    function ge(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint16 a, euint32 b)  and returns the result.
     */
    function gt(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint16 a, euint32 b)  and returns the result.
     */
    function le(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint16 a, euint32 b)  and returns the result.
     */
    function lt(euint16 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint16 a, euint32 b)  and returns the result.
     */
    function min(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint16 a, euint32 b)  and returns the result.
     */
    function max(euint16 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(asEuint32(a)), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint16 a, euint64 b)  and returns the result.
     */
    function add(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint16 a, euint64 b)  and returns the result.
     */
    function sub(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, euint64 b)  and returns the result.
     */
    function mul(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint64 b)  and returns the result.
     */
    function and(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint64 b)  and returns the result.
     */
    function or(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint64 b)  and returns the result.
     */
    function xor(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint64 b)  and returns the result.
     */
    function eq(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint64 b)  and returns the result.
     */
    function ne(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint16 a, euint64 b)  and returns the result.
     */
    function ge(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint16 a, euint64 b)  and returns the result.
     */
    function gt(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint16 a, euint64 b)  and returns the result.
     */
    function le(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint16 a, euint64 b)  and returns the result.
     */
    function lt(euint16 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint16 a, euint64 b)  and returns the result.
     */
    function min(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint16 a, euint64 b)  and returns the result.
     */
    function max(euint16 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint16 a, euint128 b)  and returns the result.
     */
    function add(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint16 a, euint128 b)  and returns the result.
     */
    function sub(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, euint128 b)  and returns the result.
     */
    function mul(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint128 b)  and returns the result.
     */
    function and(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint128 b)  and returns the result.
     */
    function or(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint128 b)  and returns the result.
     */
    function xor(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint128 b)  and returns the result.
     */
    function eq(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint128 b)  and returns the result.
     */
    function ne(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint16 a, euint128 b)  and returns the result.
     */
    function ge(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint16 a, euint128 b)  and returns the result.
     */
    function gt(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint16 a, euint128 b)  and returns the result.
     */
    function le(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint16 a, euint128 b)  and returns the result.
     */
    function lt(euint16 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint16 a, euint128 b)  and returns the result.
     */
    function min(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint16 a, euint128 b)  and returns the result.
     */
    function max(euint16 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint16 a, euint256 b)  and returns the result.
     */
    function and(euint16 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint16 a, euint256 b)  and returns the result.
     */
    function or(euint16 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint16 a, euint256 b)  and returns the result.
     */
    function xor(euint16 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint16 a, euint256 b)  and returns the result.
     */
    function eq(euint16 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint16 a, euint256 b)  and returns the result.
     */
    function ne(euint16 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint32 a, euint8 b)  and returns the result.
     */
    function add(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates sub(euint32 a, euint8 b)  and returns the result.
     */
    function sub(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, euint8 b)  and returns the result.
     */
    function mul(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint8 b)  and returns the result.
     */
    function and(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint8 b)  and returns the result.
     */
    function or(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint8 b)  and returns the result.
     */
    function xor(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint8 b)  and returns the result.
     */
    function eq(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint8 b)  and returns the result.
     */
    function ne(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates ge(euint32 a, euint8 b)  and returns the result.
     */
    function ge(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates gt(euint32 a, euint8 b)  and returns the result.
     */
    function gt(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates le(euint32 a, euint8 b)  and returns the result.
     */
    function le(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates lt(euint32 a, euint8 b)  and returns the result.
     */
    function lt(euint32 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates min(euint32 a, euint8 b)  and returns the result.
     */
    function min(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates max(euint32 a, euint8 b)  and returns the result.
     */
    function max(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates add(euint32 a, euint16 b)  and returns the result.
     */
    function add(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates sub(euint32 a, euint16 b)  and returns the result.
     */
    function sub(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, euint16 b)  and returns the result.
     */
    function mul(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint16 b)  and returns the result.
     */
    function and(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint16 b)  and returns the result.
     */
    function or(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint16 b)  and returns the result.
     */
    function xor(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint16 b)  and returns the result.
     */
    function eq(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint16 b)  and returns the result.
     */
    function ne(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates ge(euint32 a, euint16 b)  and returns the result.
     */
    function ge(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates gt(euint32 a, euint16 b)  and returns the result.
     */
    function gt(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates le(euint32 a, euint16 b)  and returns the result.
     */
    function le(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates lt(euint32 a, euint16 b)  and returns the result.
     */
    function lt(euint32 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates min(euint32 a, euint16 b)  and returns the result.
     */
    function min(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates max(euint32 a, euint16 b)  and returns the result.
     */
    function max(euint32 a, euint16 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates add(euint32 a, euint32 b)  and returns the result.
     */
    function add(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint32 a, euint32 b)  and returns the result.
     */
    function sub(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, euint32 b)  and returns the result.
     */
    function mul(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint32 b)  and returns the result.
     */
    function and(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint32 b)  and returns the result.
     */
    function or(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint32 b)  and returns the result.
     */
    function xor(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint32 b)  and returns the result.
     */
    function eq(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint32 b)  and returns the result.
     */
    function ne(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint32 a, euint32 b)  and returns the result.
     */
    function ge(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint32 a, euint32 b)  and returns the result.
     */
    function gt(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint32 a, euint32 b)  and returns the result.
     */
    function le(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint32 a, euint32 b)  and returns the result.
     */
    function lt(euint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint32 a, euint32 b)  and returns the result.
     */
    function min(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint32 a, euint32 b)  and returns the result.
     */
    function max(euint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(a), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint32 a, euint64 b)  and returns the result.
     */
    function add(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint32 a, euint64 b)  and returns the result.
     */
    function sub(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, euint64 b)  and returns the result.
     */
    function mul(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint64 b)  and returns the result.
     */
    function and(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint64 b)  and returns the result.
     */
    function or(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint64 b)  and returns the result.
     */
    function xor(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint64 b)  and returns the result.
     */
    function eq(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint64 b)  and returns the result.
     */
    function ne(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint32 a, euint64 b)  and returns the result.
     */
    function ge(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint32 a, euint64 b)  and returns the result.
     */
    function gt(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint32 a, euint64 b)  and returns the result.
     */
    function le(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint32 a, euint64 b)  and returns the result.
     */
    function lt(euint32 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint32 a, euint64 b)  and returns the result.
     */
    function min(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint32 a, euint64 b)  and returns the result.
     */
    function max(euint32 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(asEuint64(a)), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint32 a, euint128 b)  and returns the result.
     */
    function add(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint32 a, euint128 b)  and returns the result.
     */
    function sub(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, euint128 b)  and returns the result.
     */
    function mul(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint128 b)  and returns the result.
     */
    function and(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint128 b)  and returns the result.
     */
    function or(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint128 b)  and returns the result.
     */
    function xor(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint128 b)  and returns the result.
     */
    function eq(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint128 b)  and returns the result.
     */
    function ne(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint32 a, euint128 b)  and returns the result.
     */
    function ge(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint32 a, euint128 b)  and returns the result.
     */
    function gt(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint32 a, euint128 b)  and returns the result.
     */
    function le(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint32 a, euint128 b)  and returns the result.
     */
    function lt(euint32 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint32 a, euint128 b)  and returns the result.
     */
    function min(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint32 a, euint128 b)  and returns the result.
     */
    function max(euint32 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint32 a, euint256 b)  and returns the result.
     */
    function and(euint32 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint32 a, euint256 b)  and returns the result.
     */
    function or(euint32 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint32 a, euint256 b)  and returns the result.
     */
    function xor(euint32 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint32 a, euint256 b)  and returns the result.
     */
    function eq(euint32 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint32 a, euint256 b)  and returns the result.
     */
    function ne(euint32 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint64 a, euint8 b)  and returns the result.
     */
    function add(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates sub(euint64 a, euint8 b)  and returns the result.
     */
    function sub(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, euint8 b)  and returns the result.
     */
    function mul(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint8 b)  and returns the result.
     */
    function and(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint8 b)  and returns the result.
     */
    function or(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint8 b)  and returns the result.
     */
    function xor(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint8 b)  and returns the result.
     */
    function eq(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint8 b)  and returns the result.
     */
    function ne(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ge(euint64 a, euint8 b)  and returns the result.
     */
    function ge(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates gt(euint64 a, euint8 b)  and returns the result.
     */
    function gt(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates le(euint64 a, euint8 b)  and returns the result.
     */
    function le(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates lt(euint64 a, euint8 b)  and returns the result.
     */
    function lt(euint64 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates min(euint64 a, euint8 b)  and returns the result.
     */
    function min(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates max(euint64 a, euint8 b)  and returns the result.
     */
    function max(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates add(euint64 a, euint16 b)  and returns the result.
     */
    function add(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates sub(euint64 a, euint16 b)  and returns the result.
     */
    function sub(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, euint16 b)  and returns the result.
     */
    function mul(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint16 b)  and returns the result.
     */
    function and(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint16 b)  and returns the result.
     */
    function or(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint16 b)  and returns the result.
     */
    function xor(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint16 b)  and returns the result.
     */
    function eq(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint16 b)  and returns the result.
     */
    function ne(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ge(euint64 a, euint16 b)  and returns the result.
     */
    function ge(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates gt(euint64 a, euint16 b)  and returns the result.
     */
    function gt(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates le(euint64 a, euint16 b)  and returns the result.
     */
    function le(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates lt(euint64 a, euint16 b)  and returns the result.
     */
    function lt(euint64 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates min(euint64 a, euint16 b)  and returns the result.
     */
    function min(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates max(euint64 a, euint16 b)  and returns the result.
     */
    function max(euint64 a, euint16 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates add(euint64 a, euint32 b)  and returns the result.
     */
    function add(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates sub(euint64 a, euint32 b)  and returns the result.
     */
    function sub(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, euint32 b)  and returns the result.
     */
    function mul(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint32 b)  and returns the result.
     */
    function and(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint32 b)  and returns the result.
     */
    function or(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint32 b)  and returns the result.
     */
    function xor(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint32 b)  and returns the result.
     */
    function eq(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint32 b)  and returns the result.
     */
    function ne(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates ge(euint64 a, euint32 b)  and returns the result.
     */
    function ge(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates gt(euint64 a, euint32 b)  and returns the result.
     */
    function gt(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates le(euint64 a, euint32 b)  and returns the result.
     */
    function le(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates lt(euint64 a, euint32 b)  and returns the result.
     */
    function lt(euint64 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates min(euint64 a, euint32 b)  and returns the result.
     */
    function min(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates max(euint64 a, euint32 b)  and returns the result.
     */
    function max(euint64 a, euint32 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates add(euint64 a, euint64 b)  and returns the result.
     */
    function add(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint64 a, euint64 b)  and returns the result.
     */
    function sub(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, euint64 b)  and returns the result.
     */
    function mul(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint64 b)  and returns the result.
     */
    function and(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint64 b)  and returns the result.
     */
    function or(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint64 b)  and returns the result.
     */
    function xor(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint64 b)  and returns the result.
     */
    function eq(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint64 b)  and returns the result.
     */
    function ne(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint64 a, euint64 b)  and returns the result.
     */
    function ge(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint64 a, euint64 b)  and returns the result.
     */
    function gt(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint64 a, euint64 b)  and returns the result.
     */
    function le(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint64 a, euint64 b)  and returns the result.
     */
    function lt(euint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint64 a, euint64 b)  and returns the result.
     */
    function min(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint64 a, euint64 b)  and returns the result.
     */
    function max(euint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(a), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint64 a, euint128 b)  and returns the result.
     */
    function add(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint64 a, euint128 b)  and returns the result.
     */
    function sub(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, euint128 b)  and returns the result.
     */
    function mul(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint128 b)  and returns the result.
     */
    function and(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint128 b)  and returns the result.
     */
    function or(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint128 b)  and returns the result.
     */
    function xor(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint128 b)  and returns the result.
     */
    function eq(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint128 b)  and returns the result.
     */
    function ne(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint64 a, euint128 b)  and returns the result.
     */
    function ge(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint64 a, euint128 b)  and returns the result.
     */
    function gt(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint64 a, euint128 b)  and returns the result.
     */
    function le(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint64 a, euint128 b)  and returns the result.
     */
    function lt(euint64 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint64 a, euint128 b)  and returns the result.
     */
    function min(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint64 a, euint128 b)  and returns the result.
     */
    function max(euint64 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(asEuint128(a)), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint64 a, euint256 b)  and returns the result.
     */
    function and(euint64 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint64 a, euint256 b)  and returns the result.
     */
    function or(euint64 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint64 a, euint256 b)  and returns the result.
     */
    function xor(euint64 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint64 a, euint256 b)  and returns the result.
     */
    function eq(euint64 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint64 a, euint256 b)  and returns the result.
     */
    function ne(euint64 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates add(euint128 a, euint8 b)  and returns the result.
     */
    function add(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates sub(euint128 a, euint8 b)  and returns the result.
     */
    function sub(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, euint8 b)  and returns the result.
     */
    function mul(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint8 b)  and returns the result.
     */
    function and(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint8 b)  and returns the result.
     */
    function or(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint8 b)  and returns the result.
     */
    function xor(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint8 b)  and returns the result.
     */
    function eq(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint8 b)  and returns the result.
     */
    function ne(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ge(euint128 a, euint8 b)  and returns the result.
     */
    function ge(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates gt(euint128 a, euint8 b)  and returns the result.
     */
    function gt(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates le(euint128 a, euint8 b)  and returns the result.
     */
    function le(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates lt(euint128 a, euint8 b)  and returns the result.
     */
    function lt(euint128 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates min(euint128 a, euint8 b)  and returns the result.
     */
    function min(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates max(euint128 a, euint8 b)  and returns the result.
     */
    function max(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates add(euint128 a, euint16 b)  and returns the result.
     */
    function add(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates sub(euint128 a, euint16 b)  and returns the result.
     */
    function sub(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, euint16 b)  and returns the result.
     */
    function mul(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint16 b)  and returns the result.
     */
    function and(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint16 b)  and returns the result.
     */
    function or(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint16 b)  and returns the result.
     */
    function xor(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint16 b)  and returns the result.
     */
    function eq(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint16 b)  and returns the result.
     */
    function ne(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ge(euint128 a, euint16 b)  and returns the result.
     */
    function ge(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates gt(euint128 a, euint16 b)  and returns the result.
     */
    function gt(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates le(euint128 a, euint16 b)  and returns the result.
     */
    function le(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates lt(euint128 a, euint16 b)  and returns the result.
     */
    function lt(euint128 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates min(euint128 a, euint16 b)  and returns the result.
     */
    function min(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates max(euint128 a, euint16 b)  and returns the result.
     */
    function max(euint128 a, euint16 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates add(euint128 a, euint32 b)  and returns the result.
     */
    function add(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates sub(euint128 a, euint32 b)  and returns the result.
     */
    function sub(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, euint32 b)  and returns the result.
     */
    function mul(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint32 b)  and returns the result.
     */
    function and(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint32 b)  and returns the result.
     */
    function or(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint32 b)  and returns the result.
     */
    function xor(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint32 b)  and returns the result.
     */
    function eq(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint32 b)  and returns the result.
     */
    function ne(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ge(euint128 a, euint32 b)  and returns the result.
     */
    function ge(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates gt(euint128 a, euint32 b)  and returns the result.
     */
    function gt(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates le(euint128 a, euint32 b)  and returns the result.
     */
    function le(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates lt(euint128 a, euint32 b)  and returns the result.
     */
    function lt(euint128 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates min(euint128 a, euint32 b)  and returns the result.
     */
    function min(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates max(euint128 a, euint32 b)  and returns the result.
     */
    function max(euint128 a, euint32 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates add(euint128 a, euint64 b)  and returns the result.
     */
    function add(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates sub(euint128 a, euint64 b)  and returns the result.
     */
    function sub(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, euint64 b)  and returns the result.
     */
    function mul(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint64 b)  and returns the result.
     */
    function and(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint64 b)  and returns the result.
     */
    function or(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint64 b)  and returns the result.
     */
    function xor(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint64 b)  and returns the result.
     */
    function eq(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint64 b)  and returns the result.
     */
    function ne(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates ge(euint128 a, euint64 b)  and returns the result.
     */
    function ge(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates gt(euint128 a, euint64 b)  and returns the result.
     */
    function gt(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates le(euint128 a, euint64 b)  and returns the result.
     */
    function le(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates lt(euint128 a, euint64 b)  and returns the result.
     */
    function lt(euint128 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates min(euint128 a, euint64 b)  and returns the result.
     */
    function min(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates max(euint128 a, euint64 b)  and returns the result.
     */
    function max(euint128 a, euint64 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates add(euint128 a, euint128 b)  and returns the result.
     */
    function add(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates sub(euint128 a, euint128 b)  and returns the result.
     */
    function sub(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, euint128 b)  and returns the result.
     */
    function mul(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint128 b)  and returns the result.
     */
    function and(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint128 b)  and returns the result.
     */
    function or(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint128 b)  and returns the result.
     */
    function xor(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint128 b)  and returns the result.
     */
    function eq(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint128 b)  and returns the result.
     */
    function ne(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates ge(euint128 a, euint128 b)  and returns the result.
     */
    function ge(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates gt(euint128 a, euint128 b)  and returns the result.
     */
    function gt(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates le(euint128 a, euint128 b)  and returns the result.
     */
    function le(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates lt(euint128 a, euint128 b)  and returns the result.
     */
    function lt(euint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates min(euint128 a, euint128 b)  and returns the result.
     */
    function min(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates max(euint128 a, euint128 b)  and returns the result.
     */
    function max(euint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint128 a, euint256 b)  and returns the result.
     */
    function and(euint128 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint128 a, euint256 b)  and returns the result.
     */
    function or(euint128 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint128 a, euint256 b)  and returns the result.
     */
    function xor(euint128 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint128 a, euint256 b)  and returns the result.
     */
    function eq(euint128 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint128 a, euint256 b)  and returns the result.
     */
    function ne(euint128 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(asEuint256(a)), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(eaddress a, eaddress b) and returns the result.
     */
    function eq(eaddress a, eaddress b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEaddress(address(0));
        }
        if (!isInitialized(b)) {
            b = asEaddress(address(0));
        }
        return ebool.wrap(Impl.eq(eaddress.unwrap(a), eaddress.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(eaddress a, eaddress b) and returns the result.
     */
    function ne(eaddress a, eaddress b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEaddress(address(0));
        }
        if (!isInitialized(b)) {
            b = asEaddress(address(0));
        }
        return ebool.wrap(Impl.ne(eaddress.unwrap(a), eaddress.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint8 b)  and returns the result.
     */
    function and(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint8 b)  and returns the result.
     */
    function or(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint8 b)  and returns the result.
     */
    function xor(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint8 b)  and returns the result.
     */
    function eq(euint256 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint8 b)  and returns the result.
     */
    function ne(euint256 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint16 b)  and returns the result.
     */
    function and(euint256 a, euint16 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint16 b)  and returns the result.
     */
    function or(euint256 a, euint16 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint16 b)  and returns the result.
     */
    function xor(euint256 a, euint16 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint16 b)  and returns the result.
     */
    function eq(euint256 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint16 b)  and returns the result.
     */
    function ne(euint256 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint32 b)  and returns the result.
     */
    function and(euint256 a, euint32 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint32 b)  and returns the result.
     */
    function or(euint256 a, euint32 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint32 b)  and returns the result.
     */
    function xor(euint256 a, euint32 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint32 b)  and returns the result.
     */
    function eq(euint256 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint32 b)  and returns the result.
     */
    function ne(euint256 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint64 b)  and returns the result.
     */
    function and(euint256 a, euint64 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint64 b)  and returns the result.
     */
    function or(euint256 a, euint64 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint64 b)  and returns the result.
     */
    function xor(euint256 a, euint64 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint64 b)  and returns the result.
     */
    function eq(euint256 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint64 b)  and returns the result.
     */
    function ne(euint256 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint128 b)  and returns the result.
     */
    function and(euint256 a, euint128 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint128 b)  and returns the result.
     */
    function or(euint256 a, euint128 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint128 b)  and returns the result.
     */
    function xor(euint256 a, euint128 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint128 b)  and returns the result.
     */
    function eq(euint256 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint128 b)  and returns the result.
     */
    function ne(euint256 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates and(euint256 a, euint256 b)  and returns the result.
     */
    function and(euint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates or(euint256 a, euint256 b)  and returns the result.
     */
    function or(euint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates xor(euint256 a, euint256 b)  and returns the result.
     */
    function xor(euint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates eq(euint256 a, euint256 b)  and returns the result.
     */
    function eq(euint256 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates ne(euint256 a, euint256 b)  and returns the result.
     */
    function ne(euint256 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), euint256.unwrap(b), false));
    }

    /**
     * @dev Evaluates and(ebool a, bool b) and returns the result.
     */
    function and(ebool a, bool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        return ebool.wrap(Impl.and(ebool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates and(bool a, ebool b) and returns the result.
     */
    function and(bool a, ebool b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.and(ebool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates or(ebool a, bool b) and returns the result.
     */
    function or(ebool a, bool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        return ebool.wrap(Impl.or(ebool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates or(bool a, ebool b) and returns the result.
     */
    function or(bool a, ebool b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.or(ebool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates xor(ebool a, bool b) and returns the result.
     */
    function xor(ebool a, bool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        return ebool.wrap(Impl.xor(ebool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates xor(bool a, ebool b) and returns the result.
     */
    function xor(bool a, ebool b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.xor(ebool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates eq(ebool a, bool b) and returns the result.
     */
    function eq(ebool a, bool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        return ebool.wrap(Impl.eq(ebool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates eq(bool a, ebool b) and returns the result.
     */
    function eq(bool a, ebool b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.eq(ebool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates ne(ebool a, bool b) and returns the result.
     */
    function ne(ebool a, bool b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEbool(false);
        }
        return ebool.wrap(Impl.ne(ebool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates ne(bool a, ebool b) and returns the result.
     */
    function ne(bool a, ebool b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEbool(false);
        }
        return ebool.wrap(Impl.ne(ebool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }

    /**
     * @dev Evaluates add(euint8 a, uint8 b) and returns the result.
     */
    function add(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.add(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates add(uint8 a, euint8 b) and returns the result.
     */
    function add(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.add(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates sub(euint8 a, uint8 b) and returns the result.
     */
    function sub(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.sub(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates sub(uint8 a, euint8 b) and returns the result.
     */
    function sub(uint8 a, euint8 b) internal returns (euint8) {
        euint8 aEnc = asEuint8(a);
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.sub(euint8.unwrap(aEnc), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint8 a, uint8 b) and returns the result.
     */
    function mul(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.mul(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates mul(uint8 a, euint8 b) and returns the result.
     */
    function mul(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.mul(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates div(euint8 a, uint8 b) and returns the result.
     */
    function div(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.div(euint8.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates rem(euint8 a, uint8 b) and returns the result.
     */
    function rem(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.rem(euint8.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates and(euint8 a, uint8 b) and returns the result.
     */
    function and(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.and(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint8 a, euint8 b) and returns the result.
     */
    function and(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.and(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint8 a, uint8 b) and returns the result.
     */
    function or(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.or(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint8 a, euint8 b) and returns the result.
     */
    function or(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.or(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint8 a, uint8 b) and returns the result.
     */
    function xor(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.xor(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint8 a, euint8 b) and returns the result.
     */
    function xor(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.xor(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint8 a, uint8 b) and returns the result.
     */
    function eq(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint8 a, euint8 b) and returns the result.
     */
    function eq(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.eq(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint8 a, uint8 b) and returns the result.
     */
    function ne(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint8 a, euint8 b) and returns the result.
     */
    function ne(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ne(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ge(euint8 a, uint8 b) and returns the result.
     */
    function ge(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ge(uint8 a, euint8 b) and returns the result.
     */
    function ge(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates gt(euint8 a, uint8 b) and returns the result.
     */
    function gt(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates gt(uint8 a, euint8 b) and returns the result.
     */
    function gt(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates le(euint8 a, uint8 b) and returns the result.
     */
    function le(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.le(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates le(uint8 a, euint8 b) and returns the result.
     */
    function le(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.ge(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates lt(euint8 a, uint8 b) and returns the result.
     */
    function lt(euint8 a, uint8 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return ebool.wrap(Impl.lt(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates lt(uint8 a, euint8 b) and returns the result.
     */
    function lt(uint8 a, euint8 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return ebool.wrap(Impl.gt(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates min(euint8 a, uint8 b) and returns the result.
     */
    function min(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.min(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates min(uint8 a, euint8 b) and returns the result.
     */
    function min(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.min(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates max(euint8 a, uint8 b) and returns the result.
     */
    function max(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.max(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates max(uint8 a, euint8 b) and returns the result.
     */
    function max(uint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.max(euint8.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates add(euint16 a, uint16 b) and returns the result.
     */
    function add(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.add(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates add(uint16 a, euint16 b) and returns the result.
     */
    function add(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.add(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates sub(euint16 a, uint16 b) and returns the result.
     */
    function sub(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.sub(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates sub(uint16 a, euint16 b) and returns the result.
     */
    function sub(uint16 a, euint16 b) internal returns (euint16) {
        euint16 aEnc = asEuint16(a);
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.sub(euint16.unwrap(aEnc), euint16.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint16 a, uint16 b) and returns the result.
     */
    function mul(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.mul(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates mul(uint16 a, euint16 b) and returns the result.
     */
    function mul(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.mul(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates div(euint16 a, uint16 b) and returns the result.
     */
    function div(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.div(euint16.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates rem(euint16 a, uint16 b) and returns the result.
     */
    function rem(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.rem(euint16.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates and(euint16 a, uint16 b) and returns the result.
     */
    function and(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.and(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint16 a, euint16 b) and returns the result.
     */
    function and(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.and(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint16 a, uint16 b) and returns the result.
     */
    function or(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.or(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint16 a, euint16 b) and returns the result.
     */
    function or(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.or(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint16 a, uint16 b) and returns the result.
     */
    function xor(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.xor(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint16 a, euint16 b) and returns the result.
     */
    function xor(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.xor(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint16 a, uint16 b) and returns the result.
     */
    function eq(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint16 a, euint16 b) and returns the result.
     */
    function eq(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.eq(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint16 a, uint16 b) and returns the result.
     */
    function ne(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint16 a, euint16 b) and returns the result.
     */
    function ne(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ne(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ge(euint16 a, uint16 b) and returns the result.
     */
    function ge(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ge(uint16 a, euint16 b) and returns the result.
     */
    function ge(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates gt(euint16 a, uint16 b) and returns the result.
     */
    function gt(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates gt(uint16 a, euint16 b) and returns the result.
     */
    function gt(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates le(euint16 a, uint16 b) and returns the result.
     */
    function le(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.le(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates le(uint16 a, euint16 b) and returns the result.
     */
    function le(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.ge(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates lt(euint16 a, uint16 b) and returns the result.
     */
    function lt(euint16 a, uint16 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return ebool.wrap(Impl.lt(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates lt(uint16 a, euint16 b) and returns the result.
     */
    function lt(uint16 a, euint16 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return ebool.wrap(Impl.gt(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates min(euint16 a, uint16 b) and returns the result.
     */
    function min(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.min(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates min(uint16 a, euint16 b) and returns the result.
     */
    function min(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.min(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates max(euint16 a, uint16 b) and returns the result.
     */
    function max(euint16 a, uint16 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.max(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates max(uint16 a, euint16 b) and returns the result.
     */
    function max(uint16 a, euint16 b) internal returns (euint16) {
        if (!isInitialized(b)) {
            b = asEuint16(0);
        }
        return euint16.wrap(Impl.max(euint16.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates add(euint32 a, uint32 b) and returns the result.
     */
    function add(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates add(uint32 a, euint32 b) and returns the result.
     */
    function add(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.add(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates sub(euint32 a, uint32 b) and returns the result.
     */
    function sub(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates sub(uint32 a, euint32 b) and returns the result.
     */
    function sub(uint32 a, euint32 b) internal returns (euint32) {
        euint32 aEnc = asEuint32(a);
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.sub(euint32.unwrap(aEnc), euint32.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint32 a, uint32 b) and returns the result.
     */
    function mul(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates mul(uint32 a, euint32 b) and returns the result.
     */
    function mul(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.mul(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates div(euint32 a, uint32 b) and returns the result.
     */
    function div(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.div(euint32.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates rem(euint32 a, uint32 b) and returns the result.
     */
    function rem(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.rem(euint32.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates and(euint32 a, uint32 b) and returns the result.
     */
    function and(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint32 a, euint32 b) and returns the result.
     */
    function and(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.and(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint32 a, uint32 b) and returns the result.
     */
    function or(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint32 a, euint32 b) and returns the result.
     */
    function or(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.or(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint32 a, uint32 b) and returns the result.
     */
    function xor(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint32 a, euint32 b) and returns the result.
     */
    function xor(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.xor(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint32 a, uint32 b) and returns the result.
     */
    function eq(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint32 a, euint32 b) and returns the result.
     */
    function eq(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.eq(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint32 a, uint32 b) and returns the result.
     */
    function ne(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint32 a, euint32 b) and returns the result.
     */
    function ne(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ne(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ge(euint32 a, uint32 b) and returns the result.
     */
    function ge(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ge(uint32 a, euint32 b) and returns the result.
     */
    function ge(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates gt(euint32 a, uint32 b) and returns the result.
     */
    function gt(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates gt(uint32 a, euint32 b) and returns the result.
     */
    function gt(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates le(euint32 a, uint32 b) and returns the result.
     */
    function le(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.le(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates le(uint32 a, euint32 b) and returns the result.
     */
    function le(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.ge(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates lt(euint32 a, uint32 b) and returns the result.
     */
    function lt(euint32 a, uint32 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return ebool.wrap(Impl.lt(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates lt(uint32 a, euint32 b) and returns the result.
     */
    function lt(uint32 a, euint32 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return ebool.wrap(Impl.gt(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates min(euint32 a, uint32 b) and returns the result.
     */
    function min(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates min(uint32 a, euint32 b) and returns the result.
     */
    function min(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.min(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates max(euint32 a, uint32 b) and returns the result.
     */
    function max(euint32 a, uint32 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates max(uint32 a, euint32 b) and returns the result.
     */
    function max(uint32 a, euint32 b) internal returns (euint32) {
        if (!isInitialized(b)) {
            b = asEuint32(0);
        }
        return euint32.wrap(Impl.max(euint32.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates add(euint64 a, uint64 b) and returns the result.
     */
    function add(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates add(uint64 a, euint64 b) and returns the result.
     */
    function add(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.add(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates sub(euint64 a, uint64 b) and returns the result.
     */
    function sub(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates sub(uint64 a, euint64 b) and returns the result.
     */
    function sub(uint64 a, euint64 b) internal returns (euint64) {
        euint64 aEnc = asEuint64(a);
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.sub(euint64.unwrap(aEnc), euint64.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint64 a, uint64 b) and returns the result.
     */
    function mul(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates mul(uint64 a, euint64 b) and returns the result.
     */
    function mul(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.mul(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates div(euint64 a, uint64 b) and returns the result.
     */
    function div(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.div(euint64.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates rem(euint64 a, uint64 b) and returns the result.
     */
    function rem(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.rem(euint64.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates and(euint64 a, uint64 b) and returns the result.
     */
    function and(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint64 a, euint64 b) and returns the result.
     */
    function and(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.and(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint64 a, uint64 b) and returns the result.
     */
    function or(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint64 a, euint64 b) and returns the result.
     */
    function or(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.or(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint64 a, uint64 b) and returns the result.
     */
    function xor(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint64 a, euint64 b) and returns the result.
     */
    function xor(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.xor(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint64 a, uint64 b) and returns the result.
     */
    function eq(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint64 a, euint64 b) and returns the result.
     */
    function eq(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.eq(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint64 a, uint64 b) and returns the result.
     */
    function ne(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint64 a, euint64 b) and returns the result.
     */
    function ne(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ne(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ge(euint64 a, uint64 b) and returns the result.
     */
    function ge(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ge(uint64 a, euint64 b) and returns the result.
     */
    function ge(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates gt(euint64 a, uint64 b) and returns the result.
     */
    function gt(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates gt(uint64 a, euint64 b) and returns the result.
     */
    function gt(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates le(euint64 a, uint64 b) and returns the result.
     */
    function le(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.le(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates le(uint64 a, euint64 b) and returns the result.
     */
    function le(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.ge(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates lt(euint64 a, uint64 b) and returns the result.
     */
    function lt(euint64 a, uint64 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return ebool.wrap(Impl.lt(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates lt(uint64 a, euint64 b) and returns the result.
     */
    function lt(uint64 a, euint64 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return ebool.wrap(Impl.gt(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates min(euint64 a, uint64 b) and returns the result.
     */
    function min(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates min(uint64 a, euint64 b) and returns the result.
     */
    function min(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.min(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates max(euint64 a, uint64 b) and returns the result.
     */
    function max(euint64 a, uint64 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates max(uint64 a, euint64 b) and returns the result.
     */
    function max(uint64 a, euint64 b) internal returns (euint64) {
        if (!isInitialized(b)) {
            b = asEuint64(0);
        }
        return euint64.wrap(Impl.max(euint64.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates add(euint128 a, uint128 b) and returns the result.
     */
    function add(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates add(uint128 a, euint128 b) and returns the result.
     */
    function add(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.add(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates sub(euint128 a, uint128 b) and returns the result.
     */
    function sub(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates sub(uint128 a, euint128 b) and returns the result.
     */
    function sub(uint128 a, euint128 b) internal returns (euint128) {
        euint128 aEnc = asEuint128(a);
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.sub(euint128.unwrap(aEnc), euint128.unwrap(b), false));
    }

    /**
     * @dev Evaluates mul(euint128 a, uint128 b) and returns the result.
     */
    function mul(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates mul(uint128 a, euint128 b) and returns the result.
     */
    function mul(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.mul(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates div(euint128 a, uint128 b) and returns the result.
     */
    function div(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.div(euint128.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates rem(euint128 a, uint128 b) and returns the result.
     */
    function rem(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.rem(euint128.unwrap(a), bytes32(uint256(b))));
    }

    /**
     * @dev Evaluates and(euint128 a, uint128 b) and returns the result.
     */
    function and(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint128 a, euint128 b) and returns the result.
     */
    function and(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.and(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint128 a, uint128 b) and returns the result.
     */
    function or(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint128 a, euint128 b) and returns the result.
     */
    function or(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.or(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint128 a, uint128 b) and returns the result.
     */
    function xor(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint128 a, euint128 b) and returns the result.
     */
    function xor(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.xor(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint128 a, uint128 b) and returns the result.
     */
    function eq(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint128 a, euint128 b) and returns the result.
     */
    function eq(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.eq(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint128 a, uint128 b) and returns the result.
     */
    function ne(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint128 a, euint128 b) and returns the result.
     */
    function ne(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ne(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ge(euint128 a, uint128 b) and returns the result.
     */
    function ge(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ge(uint128 a, euint128 b) and returns the result.
     */
    function ge(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates gt(euint128 a, uint128 b) and returns the result.
     */
    function gt(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates gt(uint128 a, euint128 b) and returns the result.
     */
    function gt(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates le(euint128 a, uint128 b) and returns the result.
     */
    function le(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.le(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates le(uint128 a, euint128 b) and returns the result.
     */
    function le(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.ge(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates lt(euint128 a, uint128 b) and returns the result.
     */
    function lt(euint128 a, uint128 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return ebool.wrap(Impl.lt(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates lt(uint128 a, euint128 b) and returns the result.
     */
    function lt(uint128 a, euint128 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return ebool.wrap(Impl.gt(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates min(euint128 a, uint128 b) and returns the result.
     */
    function min(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates min(uint128 a, euint128 b) and returns the result.
     */
    function min(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.min(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates max(euint128 a, uint128 b) and returns the result.
     */
    function max(euint128 a, uint128 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates max(uint128 a, euint128 b) and returns the result.
     */
    function max(uint128 a, euint128 b) internal returns (euint128) {
        if (!isInitialized(b)) {
            b = asEuint128(0);
        }
        return euint128.wrap(Impl.max(euint128.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(eaddress a, address b) and returns the result.
     */
    function eq(eaddress a, address b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEaddress(address(0));
        }
        return ebool.wrap(Impl.eq(eaddress.unwrap(a), bytes32(uint256(uint160(b))), true));
    }

    /**
     * @dev Evaluates eq(address a, eaddress b) and returns the result.
     */
    function eq(address a, eaddress b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEaddress(address(0));
        }
        return ebool.wrap(Impl.eq(eaddress.unwrap(b), bytes32(uint256(uint160(a))), true));
    }

    /**
     * @dev Evaluates ne(eaddress a, address b) and returns the result.
     */
    function ne(eaddress a, address b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEaddress(address(0));
        }
        return ebool.wrap(Impl.ne(eaddress.unwrap(a), bytes32(uint256(uint160(b))), true));
    }

    /**
     * @dev Evaluates ne(address a, eaddress b) and returns the result.
     */
    function ne(address a, eaddress b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEaddress(address(0));
        }
        return ebool.wrap(Impl.ne(eaddress.unwrap(b), bytes32(uint256(uint160(a))), true));
    }

    /**
     * @dev Evaluates and(euint256 a, uint256 b) and returns the result.
     */
    function and(euint256 a, uint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates and(uint256 a, euint256 b) and returns the result.
     */
    function and(uint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.and(euint256.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates or(euint256 a, uint256 b) and returns the result.
     */
    function or(euint256 a, uint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates or(uint256 a, euint256 b) and returns the result.
     */
    function or(uint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.or(euint256.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates xor(euint256 a, uint256 b) and returns the result.
     */
    function xor(euint256 a, uint256 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates xor(uint256 a, euint256 b) and returns the result.
     */
    function xor(uint256 a, euint256 b) internal returns (euint256) {
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return euint256.wrap(Impl.xor(euint256.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates eq(euint256 a, uint256 b) and returns the result.
     */
    function eq(euint256 a, uint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates eq(uint256 a, euint256 b) and returns the result.
     */
    function eq(uint256 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.eq(euint256.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates ne(euint256 a, uint256 b) and returns the result.
     */
    function ne(euint256 a, uint256 b) internal returns (ebool) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates ne(uint256 a, euint256 b) and returns the result.
     */
    function ne(uint256 a, euint256 b) internal returns (ebool) {
        if (!isInitialized(b)) {
            b = asEuint256(0);
        }
        return ebool.wrap(Impl.ne(euint256.unwrap(b), bytes32(uint256(a)), true));
    }

    /**
     * @dev Evaluates shl(euint8 a, euint8 b) and returns the result.
     */
    function shl(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.shl(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates shl(euint8 a, uint8) and returns the result.
     */
    function shl(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.shl(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint8 a, euint8 b) and returns the result.
     */
    function shr(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.shr(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates shr(euint8 a, uint8) and returns the result.
     */
    function shr(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.shr(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint8 a, euint8 b) and returns the result.
     */
    function rotl(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.rotl(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates rotl(euint8 a, uint8) and returns the result.
     */
    function rotl(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.rotl(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint8 a, euint8 b) and returns the result.
     */
    function rotr(euint8 a, euint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint8.wrap(Impl.rotr(euint8.unwrap(a), euint8.unwrap(b), false));
    }

    /**
     * @dev Evaluates rotr(euint8 a, uint8) and returns the result.
     */
    function rotr(euint8 a, uint8 b) internal returns (euint8) {
        if (!isInitialized(a)) {
            a = asEuint8(0);
        }
        return euint8.wrap(Impl.rotr(euint8.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shl(euint16 a, euint8 b) and returns the result.
     */
    function shl(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.shl(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates shl(euint16 a, uint8) and returns the result.
     */
    function shl(euint16 a, uint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.shl(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint16 a, euint8 b) and returns the result.
     */
    function shr(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.shr(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates shr(euint16 a, uint8) and returns the result.
     */
    function shr(euint16 a, uint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.shr(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint16 a, euint8 b) and returns the result.
     */
    function rotl(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.rotl(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates rotl(euint16 a, uint8) and returns the result.
     */
    function rotl(euint16 a, uint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.rotl(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint16 a, euint8 b) and returns the result.
     */
    function rotr(euint16 a, euint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint16.wrap(Impl.rotr(euint16.unwrap(a), euint16.unwrap(asEuint16(b)), false));
    }

    /**
     * @dev Evaluates rotr(euint16 a, uint8) and returns the result.
     */
    function rotr(euint16 a, uint8 b) internal returns (euint16) {
        if (!isInitialized(a)) {
            a = asEuint16(0);
        }
        return euint16.wrap(Impl.rotr(euint16.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shl(euint32 a, euint8 b) and returns the result.
     */
    function shl(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.shl(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates shl(euint32 a, uint8) and returns the result.
     */
    function shl(euint32 a, uint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.shl(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint32 a, euint8 b) and returns the result.
     */
    function shr(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.shr(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates shr(euint32 a, uint8) and returns the result.
     */
    function shr(euint32 a, uint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.shr(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint32 a, euint8 b) and returns the result.
     */
    function rotl(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.rotl(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates rotl(euint32 a, uint8) and returns the result.
     */
    function rotl(euint32 a, uint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.rotl(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint32 a, euint8 b) and returns the result.
     */
    function rotr(euint32 a, euint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint32.wrap(Impl.rotr(euint32.unwrap(a), euint32.unwrap(asEuint32(b)), false));
    }

    /**
     * @dev Evaluates rotr(euint32 a, uint8) and returns the result.
     */
    function rotr(euint32 a, uint8 b) internal returns (euint32) {
        if (!isInitialized(a)) {
            a = asEuint32(0);
        }
        return euint32.wrap(Impl.rotr(euint32.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shl(euint64 a, euint8 b) and returns the result.
     */
    function shl(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.shl(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates shl(euint64 a, uint8) and returns the result.
     */
    function shl(euint64 a, uint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.shl(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint64 a, euint8 b) and returns the result.
     */
    function shr(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.shr(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates shr(euint64 a, uint8) and returns the result.
     */
    function shr(euint64 a, uint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.shr(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint64 a, euint8 b) and returns the result.
     */
    function rotl(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.rotl(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates rotl(euint64 a, uint8) and returns the result.
     */
    function rotl(euint64 a, uint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.rotl(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint64 a, euint8 b) and returns the result.
     */
    function rotr(euint64 a, euint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint64.wrap(Impl.rotr(euint64.unwrap(a), euint64.unwrap(asEuint64(b)), false));
    }

    /**
     * @dev Evaluates rotr(euint64 a, uint8) and returns the result.
     */
    function rotr(euint64 a, uint8 b) internal returns (euint64) {
        if (!isInitialized(a)) {
            a = asEuint64(0);
        }
        return euint64.wrap(Impl.rotr(euint64.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shl(euint128 a, euint8 b) and returns the result.
     */
    function shl(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.shl(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates shl(euint128 a, uint8) and returns the result.
     */
    function shl(euint128 a, uint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.shl(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint128 a, euint8 b) and returns the result.
     */
    function shr(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.shr(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates shr(euint128 a, uint8) and returns the result.
     */
    function shr(euint128 a, uint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.shr(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint128 a, euint8 b) and returns the result.
     */
    function rotl(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.rotl(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates rotl(euint128 a, uint8) and returns the result.
     */
    function rotl(euint128 a, uint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.rotl(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint128 a, euint8 b) and returns the result.
     */
    function rotr(euint128 a, euint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint128.wrap(Impl.rotr(euint128.unwrap(a), euint128.unwrap(asEuint128(b)), false));
    }

    /**
     * @dev Evaluates rotr(euint128 a, uint8) and returns the result.
     */
    function rotr(euint128 a, uint8 b) internal returns (euint128) {
        if (!isInitialized(a)) {
            a = asEuint128(0);
        }
        return euint128.wrap(Impl.rotr(euint128.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shl(euint256 a, euint8 b) and returns the result.
     */
    function shl(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.shl(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates shl(euint256 a, uint8) and returns the result.
     */
    function shl(euint256 a, uint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.shl(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates shr(euint256 a, euint8 b) and returns the result.
     */
    function shr(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.shr(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates shr(euint256 a, uint8) and returns the result.
     */
    function shr(euint256 a, uint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.shr(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotl(euint256 a, euint8 b) and returns the result.
     */
    function rotl(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.rotl(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates rotl(euint256 a, uint8) and returns the result.
     */
    function rotl(euint256 a, uint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.rotl(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev Evaluates rotr(euint256 a, euint8 b) and returns the result.
     */
    function rotr(euint256 a, euint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        if (!isInitialized(b)) {
            b = asEuint8(0);
        }
        return euint256.wrap(Impl.rotr(euint256.unwrap(a), euint256.unwrap(asEuint256(b)), false));
    }

    /**
     * @dev Evaluates rotr(euint256 a, uint8) and returns the result.
     */
    function rotr(euint256 a, uint8 b) internal returns (euint256) {
        if (!isInitialized(a)) {
            a = asEuint256(0);
        }
        return euint256.wrap(Impl.rotr(euint256.unwrap(a), bytes32(uint256(b)), true));
    }

    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, ebool a, ebool b) internal returns (ebool) {
        return ebool.wrap(Impl.select(ebool.unwrap(control), ebool.unwrap(a), ebool.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint8 a, euint8 b) internal returns (euint8) {
        return euint8.wrap(Impl.select(ebool.unwrap(control), euint8.unwrap(a), euint8.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint16 a, euint16 b) internal returns (euint16) {
        return euint16.wrap(Impl.select(ebool.unwrap(control), euint16.unwrap(a), euint16.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint32 a, euint32 b) internal returns (euint32) {
        return euint32.wrap(Impl.select(ebool.unwrap(control), euint32.unwrap(a), euint32.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint64 a, euint64 b) internal returns (euint64) {
        return euint64.wrap(Impl.select(ebool.unwrap(control), euint64.unwrap(a), euint64.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint128 a, euint128 b) internal returns (euint128) {
        return euint128.wrap(Impl.select(ebool.unwrap(control), euint128.unwrap(a), euint128.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, eaddress a, eaddress b) internal returns (eaddress) {
        return eaddress.wrap(Impl.select(ebool.unwrap(control), eaddress.unwrap(a), eaddress.unwrap(b)));
    }
    /**
     * @dev If 'control's value is 'true', the result has the same value as 'ifTrue'.
     *      If 'control's value is 'false', the result has the same value as 'ifFalse'.
     */
    function select(ebool control, euint256 a, euint256 b) internal returns (euint256) {
        return euint256.wrap(Impl.select(ebool.unwrap(control), euint256.unwrap(a), euint256.unwrap(b)));
    }
    /**
     * @dev Casts an encrypted integer from 'euint16' to 'euint8'.
     */
    function asEuint8(euint16 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint16.unwrap(value), FheType.Uint8));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'euint8'.
     */
    function asEuint8(euint32 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint32.unwrap(value), FheType.Uint8));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'euint8'.
     */
    function asEuint8(euint64 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint64.unwrap(value), FheType.Uint8));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'euint8'.
     */
    function asEuint8(euint128 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint128.unwrap(value), FheType.Uint8));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'euint8'.
     */
    function asEuint8(euint256 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint256.unwrap(value), FheType.Uint8));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint8'.
     */
    function asEuint8(ebool b) internal returns (euint8) {
        return euint8.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint8));
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'ebool'.
     */
    function asEbool(euint8 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'euint16'.
     */
    function asEuint16(euint8 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint8.unwrap(value), FheType.Uint16));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'euint16'.
     */
    function asEuint16(euint32 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint32.unwrap(value), FheType.Uint16));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'euint16'.
     */
    function asEuint16(euint64 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint64.unwrap(value), FheType.Uint16));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'euint16'.
     */
    function asEuint16(euint128 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint128.unwrap(value), FheType.Uint16));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'euint16'.
     */
    function asEuint16(euint256 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint256.unwrap(value), FheType.Uint16));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint16'.
     */
    function asEuint16(ebool b) internal returns (euint16) {
        return euint16.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint16));
    }

    /**
     * @dev Casts an encrypted integer from 'euint16' to 'ebool'.
     */
    function asEbool(euint16 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'euint32'.
     */
    function asEuint32(euint8 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint8.unwrap(value), FheType.Uint32));
    }

    /**
     * @dev Casts an encrypted integer from 'euint16' to 'euint32'.
     */
    function asEuint32(euint16 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint16.unwrap(value), FheType.Uint32));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'euint32'.
     */
    function asEuint32(euint64 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint64.unwrap(value), FheType.Uint32));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'euint32'.
     */
    function asEuint32(euint128 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint128.unwrap(value), FheType.Uint32));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'euint32'.
     */
    function asEuint32(euint256 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint256.unwrap(value), FheType.Uint32));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint32'.
     */
    function asEuint32(ebool b) internal returns (euint32) {
        return euint32.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint32));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'ebool'.
     */
    function asEbool(euint32 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'euint64'.
     */
    function asEuint64(euint8 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint8.unwrap(value), FheType.Uint64));
    }

    /**
     * @dev Casts an encrypted integer from 'euint16' to 'euint64'.
     */
    function asEuint64(euint16 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint16.unwrap(value), FheType.Uint64));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'euint64'.
     */
    function asEuint64(euint32 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint32.unwrap(value), FheType.Uint64));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'euint64'.
     */
    function asEuint64(euint128 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint128.unwrap(value), FheType.Uint64));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'euint64'.
     */
    function asEuint64(euint256 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint256.unwrap(value), FheType.Uint64));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint64'.
     */
    function asEuint64(ebool b) internal returns (euint64) {
        return euint64.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint64));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'ebool'.
     */
    function asEbool(euint64 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'euint128'.
     */
    function asEuint128(euint8 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint8.unwrap(value), FheType.Uint128));
    }

    /**
     * @dev Casts an encrypted integer from 'euint16' to 'euint128'.
     */
    function asEuint128(euint16 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint16.unwrap(value), FheType.Uint128));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'euint128'.
     */
    function asEuint128(euint32 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint32.unwrap(value), FheType.Uint128));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'euint128'.
     */
    function asEuint128(euint64 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint64.unwrap(value), FheType.Uint128));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'euint128'.
     */
    function asEuint128(euint256 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint256.unwrap(value), FheType.Uint128));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint128'.
     */
    function asEuint128(ebool b) internal returns (euint128) {
        return euint128.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint128));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'ebool'.
     */
    function asEbool(euint128 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Casts an encrypted integer from 'euint8' to 'euint256'.
     */
    function asEuint256(euint8 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint8.unwrap(value), FheType.Uint256));
    }

    /**
     * @dev Casts an encrypted integer from 'euint16' to 'euint256'.
     */
    function asEuint256(euint16 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint16.unwrap(value), FheType.Uint256));
    }

    /**
     * @dev Casts an encrypted integer from 'euint32' to 'euint256'.
     */
    function asEuint256(euint32 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint32.unwrap(value), FheType.Uint256));
    }

    /**
     * @dev Casts an encrypted integer from 'euint64' to 'euint256'.
     */
    function asEuint256(euint64 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint64.unwrap(value), FheType.Uint256));
    }

    /**
     * @dev Casts an encrypted integer from 'euint128' to 'euint256'.
     */
    function asEuint256(euint128 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint128.unwrap(value), FheType.Uint256));
    }

    /**
    /** 
     * @dev Converts an 'ebool' to an 'euint256'.
     */
    function asEuint256(ebool b) internal returns (euint256) {
        return euint256.wrap(Impl.cast(ebool.unwrap(b), FheType.Uint256));
    }

    /**
     * @dev Casts an encrypted integer from 'euint256' to 'ebool'.
     */
    function asEbool(euint256 value) internal returns (ebool) {
        return ne(value, 0);
    }

    /**
     * @dev Evaluates not(ebool value) and returns the result.
     */
    function not(ebool value) internal returns (ebool) {
        return ebool.wrap(Impl.not(ebool.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint8 value) and returns the result.
     */
    function neg(euint8 value) internal returns (euint8) {
        return euint8.wrap(Impl.neg(euint8.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint8 value) and returns the result.
     */
    function not(euint8 value) internal returns (euint8) {
        return euint8.wrap(Impl.not(euint8.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint16 value) and returns the result.
     */
    function neg(euint16 value) internal returns (euint16) {
        return euint16.wrap(Impl.neg(euint16.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint16 value) and returns the result.
     */
    function not(euint16 value) internal returns (euint16) {
        return euint16.wrap(Impl.not(euint16.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint32 value) and returns the result.
     */
    function neg(euint32 value) internal returns (euint32) {
        return euint32.wrap(Impl.neg(euint32.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint32 value) and returns the result.
     */
    function not(euint32 value) internal returns (euint32) {
        return euint32.wrap(Impl.not(euint32.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint64 value) and returns the result.
     */
    function neg(euint64 value) internal returns (euint64) {
        return euint64.wrap(Impl.neg(euint64.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint64 value) and returns the result.
     */
    function not(euint64 value) internal returns (euint64) {
        return euint64.wrap(Impl.not(euint64.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint128 value) and returns the result.
     */
    function neg(euint128 value) internal returns (euint128) {
        return euint128.wrap(Impl.neg(euint128.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint128 value) and returns the result.
     */
    function not(euint128 value) internal returns (euint128) {
        return euint128.wrap(Impl.not(euint128.unwrap(value)));
    }

    /**
     * @dev Evaluates neg(euint256 value) and returns the result.
     */
    function neg(euint256 value) internal returns (euint256) {
        return euint256.wrap(Impl.neg(euint256.unwrap(value)));
    }

    /**
     * @dev Evaluates not(euint256 value) and returns the result.
     */
    function not(euint256 value) internal returns (euint256) {
        return euint256.wrap(Impl.not(euint256.unwrap(value)));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted ebool integer.
     */
    function fromExternal(externalEbool inputHandle, bytes memory inputProof) internal returns (ebool) {
        return ebool.wrap(Impl.verify(externalEbool.unwrap(inputHandle), inputProof, FheType.Bool));
    }

    /**
     * @dev Converts a plaintext boolean to an encrypted boolean.
     */
    function asEbool(bool value) internal returns (ebool) {
        return ebool.wrap(Impl.trivialEncrypt(value ? 1 : 0, FheType.Bool));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint8 integer.
     */
    function fromExternal(externalEuint8 inputHandle, bytes memory inputProof) internal returns (euint8) {
        return euint8.wrap(Impl.verify(externalEuint8.unwrap(inputHandle), inputProof, FheType.Uint8));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint8 integer.
     */
    function asEuint8(uint8 value) internal returns (euint8) {
        return euint8.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint8));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint16 integer.
     */
    function fromExternal(externalEuint16 inputHandle, bytes memory inputProof) internal returns (euint16) {
        return euint16.wrap(Impl.verify(externalEuint16.unwrap(inputHandle), inputProof, FheType.Uint16));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint16 integer.
     */
    function asEuint16(uint16 value) internal returns (euint16) {
        return euint16.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint16));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint32 integer.
     */
    function fromExternal(externalEuint32 inputHandle, bytes memory inputProof) internal returns (euint32) {
        return euint32.wrap(Impl.verify(externalEuint32.unwrap(inputHandle), inputProof, FheType.Uint32));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint32 integer.
     */
    function asEuint32(uint32 value) internal returns (euint32) {
        return euint32.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint32));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint64 integer.
     */
    function fromExternal(externalEuint64 inputHandle, bytes memory inputProof) internal returns (euint64) {
        return euint64.wrap(Impl.verify(externalEuint64.unwrap(inputHandle), inputProof, FheType.Uint64));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint64 integer.
     */
    function asEuint64(uint64 value) internal returns (euint64) {
        return euint64.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint64));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint128 integer.
     */
    function fromExternal(externalEuint128 inputHandle, bytes memory inputProof) internal returns (euint128) {
        return euint128.wrap(Impl.verify(externalEuint128.unwrap(inputHandle), inputProof, FheType.Uint128));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint128 integer.
     */
    function asEuint128(uint128 value) internal returns (euint128) {
        return euint128.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint128));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted eaddress integer.
     */
    function fromExternal(externalEaddress inputHandle, bytes memory inputProof) internal returns (eaddress) {
        return eaddress.wrap(Impl.verify(externalEaddress.unwrap(inputHandle), inputProof, FheType.Uint160));
    }

    /**
     * @dev Convert a plaintext value to an encrypted eaddress integer.
     */
    function asEaddress(address value) internal returns (eaddress) {
        return eaddress.wrap(Impl.trivialEncrypt(uint256(uint160(value)), FheType.Uint160));
    }

    /**
     * @dev Convert an inputHandle with corresponding inputProof to an encrypted euint256 integer.
     */
    function fromExternal(externalEuint256 inputHandle, bytes memory inputProof) internal returns (euint256) {
        return euint256.wrap(Impl.verify(externalEuint256.unwrap(inputHandle), inputProof, FheType.Uint256));
    }

    /**
     * @dev Convert a plaintext value to an encrypted euint256 integer.
     */
    function asEuint256(uint256 value) internal returns (euint256) {
        return euint256.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint256));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEbool() internal returns (ebool) {
        return ebool.wrap(Impl.rand(FheType.Bool));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint8() internal returns (euint8) {
        return euint8.wrap(Impl.rand(FheType.Uint8));
    }

    /**
     * @dev Generates a random encrypted 8-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint8(uint8 upperBound) internal returns (euint8) {
        return euint8.wrap(Impl.randBounded(upperBound, FheType.Uint8));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint16() internal returns (euint16) {
        return euint16.wrap(Impl.rand(FheType.Uint16));
    }

    /**
     * @dev Generates a random encrypted 16-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint16(uint16 upperBound) internal returns (euint16) {
        return euint16.wrap(Impl.randBounded(upperBound, FheType.Uint16));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint32() internal returns (euint32) {
        return euint32.wrap(Impl.rand(FheType.Uint32));
    }

    /**
     * @dev Generates a random encrypted 32-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint32(uint32 upperBound) internal returns (euint32) {
        return euint32.wrap(Impl.randBounded(upperBound, FheType.Uint32));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint64() internal returns (euint64) {
        return euint64.wrap(Impl.rand(FheType.Uint64));
    }

    /**
     * @dev Generates a random encrypted 64-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint64(uint64 upperBound) internal returns (euint64) {
        return euint64.wrap(Impl.randBounded(upperBound, FheType.Uint64));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint128() internal returns (euint128) {
        return euint128.wrap(Impl.rand(FheType.Uint128));
    }

    /**
     * @dev Generates a random encrypted 128-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint128(uint128 upperBound) internal returns (euint128) {
        return euint128.wrap(Impl.randBounded(upperBound, FheType.Uint128));
    }

    /**
     * @dev Generates a random encrypted value.
     */
    function randEuint256() internal returns (euint256) {
        return euint256.wrap(Impl.rand(FheType.Uint256));
    }

    /**
     * @dev Generates a random encrypted 256-bit unsigned integer in the [0, upperBound) range.
     *      The upperBound must be a power of 2.
     */
    function randEuint256(uint256 upperBound) internal returns (euint256) {
        return euint256.wrap(Impl.randBounded(upperBound, FheType.Uint256));
    }

    /**
     * @dev This function cleans the transient storage for the ACL (accounts) and the InputVerifier
     *      (input proofs).
     *      This could be useful for integration with Account Abstraction when bundling several
     *      UserOps calling the FHEVMExecutor.
     */
    function cleanTransientStorage() internal {
        Impl.cleanTransientStorageACL();
        Impl.cleanTransientStorageInputVerifier();
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(ebool value, address account) internal view returns (bool) {
        return Impl.isAllowed(ebool.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(ebool value) internal view returns (bool) {
        return Impl.isAllowed(ebool.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(ebool value, address account) internal returns (ebool) {
        Impl.allow(ebool.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(ebool value) internal returns (ebool) {
        Impl.allow(ebool.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(ebool value, address account) internal returns (ebool) {
        Impl.allowTransient(ebool.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(ebool value) internal returns (ebool) {
        Impl.makePubliclyDecryptable(ebool.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(ebool value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ebool.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint8 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint8.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint8 value) internal view returns (bool) {
        return Impl.isAllowed(euint8.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint8 value, address account) internal returns (euint8) {
        Impl.allow(euint8.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint8 value) internal returns (euint8) {
        Impl.allow(euint8.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint8 value, address account) internal returns (euint8) {
        Impl.allowTransient(euint8.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint8 value) internal returns (euint8) {
        Impl.makePubliclyDecryptable(euint8.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint8 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint8.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint16 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint16.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint16 value) internal view returns (bool) {
        return Impl.isAllowed(euint16.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint16 value, address account) internal returns (euint16) {
        Impl.allow(euint16.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint16 value) internal returns (euint16) {
        Impl.allow(euint16.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint16 value, address account) internal returns (euint16) {
        Impl.allowTransient(euint16.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint16 value) internal returns (euint16) {
        Impl.makePubliclyDecryptable(euint16.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint16 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint16.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint32 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint32.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint32 value) internal view returns (bool) {
        return Impl.isAllowed(euint32.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint32 value, address account) internal returns (euint32) {
        Impl.allow(euint32.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint32 value) internal returns (euint32) {
        Impl.allow(euint32.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint32 value, address account) internal returns (euint32) {
        Impl.allowTransient(euint32.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint32 value) internal returns (euint32) {
        Impl.makePubliclyDecryptable(euint32.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint32 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint32.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint64 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint64.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint64 value) internal view returns (bool) {
        return Impl.isAllowed(euint64.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint64 value, address account) internal returns (euint64) {
        Impl.allow(euint64.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint64 value) internal returns (euint64) {
        Impl.allow(euint64.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint64 value, address account) internal returns (euint64) {
        Impl.allowTransient(euint64.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint64 value) internal returns (euint64) {
        Impl.makePubliclyDecryptable(euint64.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint64 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint64.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint128 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint128.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint128 value) internal view returns (bool) {
        return Impl.isAllowed(euint128.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint128 value, address account) internal returns (euint128) {
        Impl.allow(euint128.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint128 value) internal returns (euint128) {
        Impl.allow(euint128.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint128 value, address account) internal returns (euint128) {
        Impl.allowTransient(euint128.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint128 value) internal returns (euint128) {
        Impl.makePubliclyDecryptable(euint128.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint128 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint128.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(eaddress value, address account) internal view returns (bool) {
        return Impl.isAllowed(eaddress.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(eaddress value) internal view returns (bool) {
        return Impl.isAllowed(eaddress.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(eaddress value, address account) internal returns (eaddress) {
        Impl.allow(eaddress.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(eaddress value) internal returns (eaddress) {
        Impl.allow(eaddress.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(eaddress value, address account) internal returns (eaddress) {
        Impl.allowTransient(eaddress.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(eaddress value) internal returns (eaddress) {
        Impl.makePubliclyDecryptable(eaddress.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(eaddress value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(eaddress.unwrap(value));
    }

    /**
     * @dev Returns whether the account is allowed to use the value.
     */
    function isAllowed(euint256 value, address account) internal view returns (bool) {
        return Impl.isAllowed(euint256.unwrap(value), account);
    }

    /**
     * @dev Returns whether the sender is allowed to use the value.
     */
    function isSenderAllowed(euint256 value) internal view returns (bool) {
        return Impl.isAllowed(euint256.unwrap(value), msg.sender);
    }

    /**
     * @dev Allows the use of value for the address account.
     */
    function allow(euint256 value, address account) internal returns (euint256) {
        Impl.allow(euint256.unwrap(value), account);
        return value;
    }

    /**
     * @dev Allows the use of value for this address (address(this)).
     */
    function allowThis(euint256 value) internal returns (euint256) {
        Impl.allow(euint256.unwrap(value), address(this));
        return value;
    }

    /**
     * @dev Allows the use of value by address account for this transaction.
     */
    function allowTransient(euint256 value, address account) internal returns (euint256) {
        Impl.allowTransient(euint256.unwrap(value), account);
        return value;
    }

    /**
     * @dev Makes the value publicly decryptable.
     */
    function makePubliclyDecryptable(euint256 value) internal returns (euint256) {
        Impl.makePubliclyDecryptable(euint256.unwrap(value));
        return value;
    }

    /**
     * @dev Returns whether the the value is publicly decryptable.
     */
    function isPubliclyDecryptable(euint256 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(euint256.unwrap(value));
    }

    /**
     * @dev Recovers the stored array of handles corresponding to requestID.
     */
    function loadRequestedHandles(uint256 requestID) internal view returns (bytes32[] memory) {
        DecryptionRequests storage $ = Impl.getDecryptionRequests();
        if ($.requestedHandles[requestID].length == 0) {
            revert NoHandleFoundForRequestID();
        }
        return $.requestedHandles[requestID];
    }

    /**
     * @dev     Calls the DecryptionOracle contract to request the decryption of a list of handles.
     * @notice  Also does the needed call to ACL::allowForDecryption with requested handles.
     */
    function requestDecryption(
        bytes32[] memory ctsHandles,
        bytes4 callbackSelector
    ) internal returns (uint256 requestID) {
        requestID = requestDecryption(ctsHandles, callbackSelector, 0);
    }

    /**
     * @dev     Calls the DecryptionOracle contract to request the decryption of a list of handles, with a custom msgValue.
     * @notice  Also does the needed call to ACL::allowForDecryption with requested handles.
     */
    function requestDecryption(
        bytes32[] memory ctsHandles,
        bytes4 callbackSelector,
        uint256 msgValue
    ) internal returns (uint256 requestID) {
        DecryptionRequests storage $ = Impl.getDecryptionRequests();
        requestID = $.counterRequest;
        CoprocessorConfig storage $$ = Impl.getCoprocessorConfig();
        IACL($$.ACLAddress).allowForDecryption(ctsHandles);
        IDecryptionOracle($$.DecryptionOracleAddress).requestDecryption{value: msgValue}(
            requestID,
            ctsHandles,
            callbackSelector
        );
        saveRequestedHandles(requestID, ctsHandles);
        $.counterRequest++;
    }

    /**
     * @dev     MUST be called inside the callback function the dApp contract to verify the signatures,
     * @dev     otherwise fake decryption results could be submitted.
     * @notice  Warning: MUST be called directly in the callback function called by the relayer.
     */
    function checkSignatures(uint256 requestID, bytes memory cleartexts, bytes memory decryptionProof) internal {
        bytes32[] memory handlesList = loadRequestedHandles(requestID);
        bool isVerified = verifySignatures(handlesList, cleartexts, decryptionProof);
        if (!isVerified) {
            revert InvalidKMSSignatures();
        }
        emit DecryptionFulfilled(requestID);
    }

    /**
     * @dev Private low-level function used to link in storage an array of handles to its associated requestID.
     */
    function saveRequestedHandles(uint256 requestID, bytes32[] memory handlesList) private {
        DecryptionRequests storage $ = Impl.getDecryptionRequests();
        if ($.requestedHandles[requestID].length != 0) {
            revert HandlesAlreadySavedForRequestID();
        }
        $.requestedHandles[requestID] = handlesList;
    }

    /**
     * @dev Private low-level function used to extract the decryptedResult bytes array and verify the KMS signatures.
     * @notice  Warning: MUST be called directly in the callback function called by the relayer.
     * @dev The callback function has the following signature:
     * - requestID (static uint256)
     * - cleartexts (dynamic bytes)
     * - decryptionProof (dynamic bytes)
     *
     * This means that the calldata is encoded in the following way:
     * - 4 bytes: selector
     * - 32 bytes: requestID
     * - 32 bytes: offset of the cleartexts
     * - 32 bytes: offset of the decryptionProof
     * - 32 bytes: length of the cleartexts (total number of bytes)
     * - n*32 bytes: the "n" cleartext values, with "n" the number of handles
     * - 32 bytes: length of the decryptionProof (total number of bytes)
     * - ... the data of the decryptionProof (signatures, extra data)
     */
    function verifySignatures(
        bytes32[] memory handlesList,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) private returns (bool) {
        // Compute the signature offset
        // This offset is computed by considering the format encoded by the KMS when creating the
        // "decryptedResult" bytes array (see comment below), which is the following:
        // - requestID: 32 bytes
        // - all "n" decrypted values (which is "cleartexts" itself): n*32 bytes ("cleartexts.length" bytes)
        // - offset of the signatures: 32 bytes
        // - the rest of signature values (lengths, offsets, values)
        // This means the expected offset to concatenate to the "decryptedResult" bytes array has
        // the following value: 32 + n*32 + 32
        // See https://docs.soliditylang.org/en/latest/abi-spec.html#use-of-dynamic-types for more details.
        // The signature offset will most likely be removed in the future,
        // see https://github.com/zama-ai/fhevm-internal/issues/345
        uint256 signaturesOffset = 32 + cleartexts.length + 32;

        // Built the "decryptedResult" bytes array
        // Currently, the "decryptedResult" is encoded (by the KMS) in the following format:
        // - n*32 bytes: the "n" decrypted values, "cleartexts" itself
        // - 32 bytes: offset of the signatures, as explained above
        // This is equivalent to concatenating the cleartexts and the signatures offset, which can
        // be done using abi.encoded in a gas efficient way.
        // The signature offset will most likely be removed in the future,
        // see https://github.com/zama-ai/fhevm-internal/issues/345
        // Here we can use "encodePacked" instead of "abi.encode" to save gas, as the cleartexts
        // and the signaturesOffset are already 32 bytes aligned (ie, no padding needed).
        bytes memory decryptedResult = abi.encodePacked(cleartexts, signaturesOffset);

        CoprocessorConfig storage $ = Impl.getCoprocessorConfig();
        return
            IKMSVerifier($.KMSVerifierAddress).verifyDecryptionEIP712KMSSignatures(
                handlesList,
                decryptedResult,
                decryptionProof
            );
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(ebool value) internal pure returns (bytes32 ct) {
        ct = ebool.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint8 value) internal pure returns (bytes32 ct) {
        ct = euint8.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint16 value) internal pure returns (bytes32 ct) {
        ct = euint16.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint32 value) internal pure returns (bytes32 ct) {
        ct = euint32.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint64 value) internal pure returns (bytes32 ct) {
        ct = euint64.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint128 value) internal pure returns (bytes32 ct) {
        ct = euint128.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(eaddress value) internal pure returns (bytes32 ct) {
        ct = eaddress.unwrap(value);
    }

    /**
     * @dev Converts handle from its custom type to the underlying bytes32. Used when requesting a decryption.
     */
    function toBytes32(euint256 value) internal pure returns (bytes32 ct) {
        ct = euint256.unwrap(value);
    }
}

// node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// node_modules/@openzeppelin/contracts/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// packages/fhevm-hardhat-template/contracts/interfaces/IFHERC20.sol

// Fhenix Protocol (last updated v0.1.0) (token/FHERC20/IFHERC20.sol)
// Inspired by OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts) (token/ERC20/IERC20.sol)

interface IFHERC20 is IERC20 {
    // -------- Public Mint / Burn Functions --------
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;

    // -------- Encrypted Mint Functions --------
    function mintEncrypted(address user, externalEuint128 amount, bytes calldata inputProof) external;
    function mintEncrypted(address user, euint128 amount) external;

    // -------- Encrypted Burn Functions --------
    function burnEncrypted(address user, externalEuint128 amount, bytes calldata inputProof) external;
    function burnEncrypted(address user, euint128 amount) external;

    // -------- Encrypted Transfer Functions --------
    function transferFromEncrypted(address from, address to, externalEuint128 amount, bytes calldata inputProof) external returns (euint128);
    function transferFromEncrypted(address from, address to, euint128 amount) external returns (euint128);
    function transferEncrypted(address to, externalEuint128 amount, bytes calldata inputProof) external returns (euint128);
    function transferEncrypted(address to, euint128 amount) external returns (euint128);

    // -------- Decrypt Balance Functions --------
    function requestBalanceDecryption(address user) external returns(uint256);
    function finalizeBalanceDecryption(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof) external;

    // -------- Encrypted Wrapping Functions --------
    function wrap(address user, uint128 amount) external;

    // -------- Encrypted Unwrapping Functions --------
    function requestUnwrap(address user, externalEuint128 amount, bytes calldata inputProof) external returns (euint128);
    function requestUnwrap(address user, euint128 amount) external returns (euint128);
    function finalizeUnwrap(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof) external;

    // -------- View for encrypted balances --------
    function encBalances(address user) external view returns (euint128);
}

// node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// node_modules/@fhevm/solidity/config/ZamaConfig.sol

/**
 * @title   ZamaConfig.
 * @notice  This library returns the FHEVM config for different networks
 *          with the contract addresses for (1) ACL, (2) CoprocessorAddress, (3) DecryptionOracleAddress, (4) KMSVerifier,
 *          which are deployed & maintained by Zama. It also returns the address of the decryption oracle.
 */
library ZamaConfig {
    function getSepoliaProtocolId() internal pure returns (uint256) {
        /// @note Zama Ethereum Sepolia protocol id is '10000 + Zama Ethereum protocol id'
        return 10001;
    }

    function getSepoliaConfig() internal pure returns (CoprocessorConfig memory) {
        return
            CoprocessorConfig({
                ACLAddress: 0x687820221192C5B662b25367F70076A37bc79b6c,
                CoprocessorAddress: 0x848B0066793BcC60346Da1F49049357399B8D595,
                DecryptionOracleAddress: SepoliaZamaOracleAddress,
                KMSVerifierAddress: 0x1364cBBf2cDF5032C47d8226a6f6FBD2AFCDacAC
            });
    }

    function getEthereumProtocolId() internal pure returns (uint256) {
        /// @note Zama Ethereum protocol id is '1'
        return 1;
    }

    function getEthereumConfig() internal pure returns (CoprocessorConfig memory) {
        /// @note The addresses below are placeholders and should be replaced with actual addresses
        /// once deployed on the Ethereum mainnet.
        return
            CoprocessorConfig({
                ACLAddress: address(0),
                CoprocessorAddress: address(0),
                DecryptionOracleAddress: address(0),
                KMSVerifierAddress: address(0)
            });
    }
}

/**
 * @title   SepoliaConfig.
 * @dev     This contract can be inherited by a contract wishing to use the FHEVM contracts provided by Zama
 *          on the Sepolia network (chainId = 11155111).
 *          Other providers may offer similar contracts deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract SepoliaConfig {
    constructor() {
        FHE.setCoprocessor(ZamaConfig.getSepoliaConfig());
    }

    function protocolId() public pure returns (uint256) {
        return ZamaConfig.getSepoliaProtocolId();
    }
}

/**
 * @title   EthereumConfig.
 * @dev     This contract can be inherited by a contract wishing to use the FHEVM contracts provided by Zama
 *          on the Ethereum (mainnet) network (chainId = 1).
 *          Other providers may offer similar contracts deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract EthereumConfig {
    constructor() {
        FHE.setCoprocessor(ZamaConfig.getEthereumConfig());
    }

    function protocolId() public pure returns (uint256) {
        return ZamaConfig.getEthereumProtocolId();
    }
}

// node_modules/@uniswap/v4-core/src/interfaces/IHooks.sol

/// @notice V4 decides whether to invoke specific hooks by inspecting the least significant bits
/// of the address that the hooks contract is deployed to.
/// For example, a hooks contract deployed to address: 0x0000000000000000000000000000000000002400
/// has the lowest bits '10 0100 0000 0000' which would cause the 'before initialize' and 'after add liquidity' hooks to be used.
/// See the Hooks library for the full spec.
/// @dev Should only be callable by the v4 PoolManager.
interface IHooks {
    /// @notice The hook called before the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @return bytes4 The function selector for the hook
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96) external returns (bytes4);

    /// @notice The hook called after the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @param tick The current tick after the state of a pool is initialized
    /// @return bytes4 The function selector for the hook
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        returns (bytes4);

    /// @notice The hook called before liquidity is added
    /// @param sender The initial msg.sender for the add liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after liquidity is added
    /// @param sender The initial msg.sender for the add liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param delta The caller's balance delta after adding liquidity; the sum of principal delta, fees accrued, and hook delta
    /// @param feesAccrued The fees accrued since the last time fees were collected from this position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BalanceDelta The hook's delta in token0 and token1. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice The hook called before liquidity is removed
    /// @param sender The initial msg.sender for the remove liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after liquidity is removed
    /// @param sender The initial msg.sender for the remove liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param delta The caller's balance delta after removing liquidity; the sum of principal delta, fees accrued, and hook delta
    /// @param feesAccrued The fees accrued since the last time fees were collected from this position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BalanceDelta The hook's delta in token0 and token1. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice The hook called before a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BeforeSwapDelta The hook's delta in specified and unspecified currencies. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    /// @return uint24 Optionally override the lp fee, only used if three conditions are met: 1. the Pool has a dynamic fee, 2. the value's 2nd highest bit is set (23rd bit, 0x400000), and 3. the value is less than or equal to the maximum fee (1 million)
    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (bytes4, BeforeSwapDelta, uint24);

    /// @notice The hook called after a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param delta The amount owed to the caller (positive) or owed to the pool (negative)
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return int128 The hook's delta in unspecified currency. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128);

    /// @notice The hook called before donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}

// node_modules/@uniswap/v4-core/src/types/PoolId.sol

type PoolId is bytes32;

/// @notice Library for computing the ID of a pool
library PoolIdLibrary {
    /// @notice Returns value equal to keccak256(abi.encode(poolKey))
    function toId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            // 0xa0 represents the total size of the poolKey struct (5 slots of 32 bytes)
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}

// node_modules/@uniswap/v4-core/src/types/PoolKey.sol

using PoolIdLibrary for PoolKey global;

/// @notice Returns the key for identifying a pool
struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically
    Currency currency0;
    /// @notice The higher currency of the pool, sorted numerically
    Currency currency1;
    /// @notice The pool LP fee, capped at 1_000_000. If the highest bit is 1, the pool has a dynamic fee and must be exactly equal to 0x800000
    uint24 fee;
    /// @notice Ticks that involve positions must be a multiple of tick spacing
    int24 tickSpacing;
    /// @notice The hooks of the pool
    IHooks hooks;
}

// node_modules/@uniswap/v4-core/src/types/PoolOperation.sol

/// @notice Parameter struct for `ModifyLiquidity` pool operations
struct ModifyLiquidityParams {
    // the lower and upper tick of the position
    int24 tickLower;
    int24 tickUpper;
    // how to modify the liquidity
    int256 liquidityDelta;
    // a value to set if you want unique liquidity positions at the same range
    bytes32 salt;
}

/// @notice Parameter struct for `Swap` pool operations
struct SwapParams {
    /// Whether to swap token0 for token1 or vice versa
    bool zeroForOne;
    /// The desired input amount if negative (exactIn), or the desired output amount if positive (exactOut)
    int256 amountSpecified;
    /// The sqrt price at which, if reached, the swap will stop executing
    uint160 sqrtPriceLimitX96;
}

// node_modules/@uniswap/v4-core/src/interfaces/IProtocolFees.sol

/// @notice Interface for all protocol-fee related functions in the pool manager
interface IProtocolFees {
    /// @notice Thrown when protocol fee is set too high
    error ProtocolFeeTooLarge(uint24 fee);

    /// @notice Thrown when collectProtocolFees or setProtocolFee is not called by the controller.
    error InvalidCaller();

    /// @notice Thrown when collectProtocolFees is attempted on a token that is synced.
    error ProtocolFeeCurrencySynced();

    /// @notice Emitted when the protocol fee controller address is updated in setProtocolFeeController.
    event ProtocolFeeControllerUpdated(address indexed protocolFeeController);

    /// @notice Emitted when the protocol fee is updated for a pool.
    event ProtocolFeeUpdated(PoolId indexed id, uint24 protocolFee);

    /// @notice Given a currency address, returns the protocol fees accrued in that currency
    /// @param currency The currency to check
    /// @return amount The amount of protocol fees accrued in the currency
    function protocolFeesAccrued(Currency currency) external view returns (uint256 amount);

    /// @notice Sets the protocol fee for the given pool
    /// @param key The key of the pool to set a protocol fee for
    /// @param newProtocolFee The fee to set
    function setProtocolFee(PoolKey memory key, uint24 newProtocolFee) external;

    /// @notice Sets the protocol fee controller
    /// @param controller The new protocol fee controller
    function setProtocolFeeController(address controller) external;

    /// @notice Collects the protocol fees for a given recipient and currency, returning the amount collected
    /// @dev This will revert if the contract is unlocked
    /// @param recipient The address to receive the protocol fees
    /// @param currency The currency to withdraw
    /// @param amount The amount of currency to withdraw
    /// @return amountCollected The amount of currency successfully withdrawn
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected);

    /// @notice Returns the current protocol fee controller address
    /// @return address The current protocol fee controller address
    function protocolFeeController() external view returns (address);
}

// packages/fhevm-hardhat-template/contracts/interfaces/ISwapManager.sol

/**
 * @title ISwapManager
 * @dev Interface for AVS SwapManager that handles batch processing
 */
interface ISwapManager {
    /**
     * @dev Submit a batch of encrypted intents for processing
     * @param batchId Unique identifier for the batch
     * @param hook Address of the hook contract
     * @param poolId Pool identifier
     * @param encryptedIntents Array of encrypted intent data
     * @param selectedOperators Operators selected for this batch
     */
    function createBatch(
        bytes32 batchId,
        address hook,
        PoolId poolId,
        bytes[] calldata encryptedIntents,
        address[] calldata selectedOperators
    ) external;

    /**
     * @dev Select operators for processing a batch
     * @param batchId Batch identifier
     * @return Selected operator addresses
     */
    function selectOperatorsForBatch(bytes32 batchId) external returns (address[] memory);

    /**
     * @dev Finalize a batch with processed data
     * @param batchId Batch identifier
     * @param batchData Processed batch data
     */
    function finalizeBatch(bytes32 batchId, bytes calldata batchData) external;
}

// packages/fhevm-hardhat-template/contracts/HybridFHERC20.sol

/**
 * @dev Minimal implementation of an FHERC20 token
 * Implementation of the bare minimum methods to make
 * the hook work with a hybrid FHE / ERC20 token
 */
contract HybridFHERC20 is ERC20, IFHERC20, SepoliaConfig {

    uint8 private _decimals;

    //errors
    error HybridFHERC20__InvalidSender();
    error HybridFHERC20__InvalidReceiver();

    //encrypted balances
    mapping(address => euint128) public encBalances;
    euint128 public totalEncryptedSupply = FHE.asEuint128(0);

    //zero constant
    euint128 private immutable ZERO = FHE.asEuint128(0);

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        FHE.allowThis(ZERO);
        _decimals = decimals_;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * Overrides the default 18 decimals from ERC20.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // ----------- Public Mint Functions --------------------
    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }

    // ----------- Public Burn Functions --------------------
    function burn(address user, uint256 amount) public {
        _burn(user, amount);
    }

    // ----------- Encrypted Mint Functions -----------------
    function mintEncrypted(address user, externalEuint128 amount, bytes calldata inputProof) public {
        _mintEnc(user, FHE.fromExternal(amount, inputProof));
    }
    
    function mintEncrypted(address user, euint128 amount) public {
        _mintEnc(user, amount);
    }

    function _mintEnc(address user, euint128 amount) internal {
        encBalances[user] = FHE.add(encBalances[user], amount);
        totalEncryptedSupply = FHE.add(totalEncryptedSupply, amount);

        FHE.allowThis(encBalances[user]);
        FHE.allow(encBalances[user], user);
        FHE.allowThis(totalEncryptedSupply);
        
        // Emit standard Transfer event with encrypted handle as value
        // This makes transfers visible on Etherscan while preserving privacy
        emit Transfer(address(0), user, uint256(euint128.unwrap(amount)));
    }

    // ----------- Encrypted Burn Functions -----------------
    function burnEncrypted(address user, externalEuint128 amount, bytes calldata inputProof) public {
        _burnEnc(user, FHE.fromExternal(amount, inputProof));
    }
    
    function burnEncrypted(address user, euint128 amount) public {
        _burnEnc(user, amount);
    }

    function _burnEnc(address user, euint128 amount) internal {
        euint128 burnAmount = _calculateBurnAmount(user, amount);
        encBalances[user] = FHE.sub(encBalances[user], burnAmount);
        totalEncryptedSupply = FHE.sub(totalEncryptedSupply, burnAmount);

        FHE.allowThis(encBalances[user]);
        FHE.allow(encBalances[user], user);
        FHE.allowThis(totalEncryptedSupply);
        
        // Emit standard Transfer event with encrypted handle as value
        emit Transfer(user, address(0), uint256(euint128.unwrap(burnAmount)));
    }

    function _calculateBurnAmount(address user, euint128 amount) internal returns(euint128){
        return FHE.select(FHE.le(amount, encBalances[user]), amount, ZERO);
    }

    // ----------- Encrypted Transfer Functions ---------------
    function transferEncrypted(address to, externalEuint128 amount, bytes calldata inputProof) external returns(euint128) {
        return _transferImpl(msg.sender, to, FHE.fromExternal(amount, inputProof));
    }

    function transferEncrypted(address to, euint128 amount) external returns(euint128) {
        return _transferImpl(msg.sender, to, amount);
    }

    function transferFromEncrypted(address from, address to, externalEuint128 amount, bytes calldata inputProof) external returns(euint128) {
        return _transferImpl(from, to, FHE.fromExternal(amount, inputProof));
    }

    function transferFromEncrypted(address from, address to, euint128 amount) external returns(euint128) {
        return _transferImpl(from, to, amount);
    }

    function _transferImpl(address from, address to, euint128 amount) internal returns (euint128) {
        //ensure sender / receiver is not 0x00
        if(from == address(0)){
            revert HybridFHERC20__InvalidSender();
        }
        if(to == address(0)){
            revert HybridFHERC20__InvalidReceiver();
        }

        // Make sure the sender has enough tokens.
        euint128 amountToSend = FHE.select(FHE.le(amount, encBalances[from]), amount, ZERO);

        // Add to the balance of `to` and subract from the balance of `from`.
        encBalances[to] = FHE.add(encBalances[to], amountToSend);
        encBalances[from] = FHE.sub(encBalances[from], amountToSend);

        //allow contract to interact with balances
        FHE.allowThis(encBalances[to]);
        FHE.allowThis(encBalances[from]);

        //allow users to interact with their balances
        FHE.allow(encBalances[to], to);
        FHE.allow(encBalances[from], from);
        
        // Emit standard Transfer event with encrypted handle as value
        emit Transfer(from, to, uint256(euint128.unwrap(amountToSend)));

        return amountToSend;
    }

    // --------- Decrypt Balance Functions ------------------
    mapping(uint256 => address) private _decryptRequests;
    
    function requestBalanceDecryption(address user) public returns(uint256) {
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = euint128.unwrap(encBalances[user]);
        uint256 requestId = FHE.requestDecryption(cts, this.finalizeBalanceDecryption.selector);
        _decryptRequests[requestId] = user;
        return requestId;
    }

    function finalizeBalanceDecryption(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof) public {
        // Verify the decryption proof and signatures
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        // Decode the decrypted value(s)
        (uint128 decryptedBalance) = abi.decode(cleartexts, (uint128));

        address user = _decryptRequests[requestId];
        require(user != address(0), "Invalid request ID");

        // Handle decryptedBalance as needed
        delete _decryptRequests[requestId];
    }

    // --------- Encrypted Wrapping Functions ---------------
    function wrap(address user, uint128 amount) external {
        _wrap(user, amount);
    }

    function _wrap(address user, uint128 amount) internal {
        //burn public balance
        _burn(user, uint256(amount));

        //mint encrypted balance
        _mintEnc(user, FHE.asEuint128(amount));
    }

    // --------- Encrypted Unwrapping Functions ---------------
    function requestUnwrap(address user, externalEuint128 amount, bytes calldata inputProof) external returns(euint128) {
        return _requestUnwrap(user, FHE.fromExternal(amount, inputProof));
    }

    function requestUnwrap(address user, euint128 amount) external returns(euint128) {
        return _requestUnwrap(user, amount);
    }

    // Removed old getUnwrapResult functions as we now use async callbacks

    mapping(uint256 => UnwrapRequest) private _unwrapRequests;
    struct UnwrapRequest {
        address user;
        euint128 burnAmount;
    }
    
    function _requestUnwrap(address user, euint128 amount) internal returns(euint128 burnAmount) {
        burnAmount = _calculateBurnAmount(user, amount);
        
        // Request decryption of burn amount
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = euint128.unwrap(burnAmount);
        uint256 requestId = FHE.requestDecryption(cts, this.finalizeUnwrap.selector);
        
        _unwrapRequests[requestId] = UnwrapRequest({
            user: user,
            burnAmount: burnAmount
        });
        
        FHE.allowThis(burnAmount);
        FHE.allow(burnAmount, msg.sender);
    }

    function finalizeUnwrap(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof) public {
        // Verify the decryption proof and signatures
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        // Decode the decrypted value(s)
        (uint128 amount) = abi.decode(cleartexts, (uint128));

        UnwrapRequest memory request = _unwrapRequests[requestId];
        require(request.user != address(0), "Invalid request ID");

        // Burn encrypted balance
        _burnEnc(request.user, request.burnAmount);

        // Mint public balance
        _mint(request.user, amount);
        
        // Clean up
        delete _unwrapRequests[requestId];
    }

    // Legacy unwrap functions removed - now using async callbacks
}

// node_modules/@uniswap/v4-core/src/interfaces/IPoolManager.sol

/// @notice Interface for the PoolManager
interface IPoolManager is IProtocolFees, IERC6909Claims, IExtsload, IExttload {
    /// @notice Thrown when a currency is not netted out after the contract is unlocked
    error CurrencyNotSettled();

    /// @notice Thrown when trying to interact with a non-initialized pool
    error PoolNotInitialized();

    /// @notice Thrown when unlock is called, but the contract is already unlocked
    error AlreadyUnlocked();

    /// @notice Thrown when a function is called that requires the contract to be unlocked, but it is not
    error ManagerLocked();

    /// @notice Pools are limited to type(int16).max tickSpacing in #initialize, to prevent overflow
    error TickSpacingTooLarge(int24 tickSpacing);

    /// @notice Pools must have a positive non-zero tickSpacing passed to #initialize
    error TickSpacingTooSmall(int24 tickSpacing);

    /// @notice PoolKey must have currencies where address(currency0) < address(currency1)
    error CurrenciesOutOfOrderOrEqual(address currency0, address currency1);

    /// @notice Thrown when a call to updateDynamicLPFee is made by an address that is not the hook,
    /// or on a pool that does not have a dynamic swap fee.
    error UnauthorizedDynamicLPFeeUpdate();

    /// @notice Thrown when trying to swap amount of 0
    error SwapAmountCannotBeZero();

    ///@notice Thrown when native currency is passed to a non native settlement
    error NonzeroNativeValue();

    /// @notice Thrown when `clear` is called with an amount that is not exactly equal to the open currency delta.
    error MustClearExactPositiveDelta();

    /// @notice Emitted when a new pool is initialized
    /// @param id The abi encoded hash of the pool key struct for the new pool
    /// @param currency0 The first currency of the pool by address sort order
    /// @param currency1 The second currency of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param hooks The hooks contract address for the pool, or address(0) if none
    /// @param sqrtPriceX96 The price of the pool on initialization
    /// @param tick The initial tick of the pool corresponding to the initialized price
    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Emitted when a liquidity position is modified
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidityDelta The amount of liquidity that was added or removed
    /// @param salt The extra data to make positions unique
    event ModifyLiquidity(
        PoolId indexed id, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta, bytes32 salt
    );

    /// @notice Emitted for swaps between currency0 and currency1
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of the price of the pool after the swap
    /// @param fee The swap fee in hundredths of a bip
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    /// @notice Emitted for donations
    /// @param id The abi encoded hash of the pool key struct for the pool that was donated to
    /// @param sender The address that initiated the donate call
    /// @param amount0 The amount donated in currency0
    /// @param amount1 The amount donated in currency1
    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1);

    /// @notice All interactions on the contract that account deltas require unlocking. A caller that calls `unlock` must implement
    /// `IUnlockCallback(msg.sender).unlockCallback(data)`, where they interact with the remaining functions on this contract.
    /// @dev The only functions callable without an unlocking are `initialize` and `updateDynamicLPFee`
    /// @param data Any data to pass to the callback, via `IUnlockCallback(msg.sender).unlockCallback(data)`
    /// @return The data returned by the call to `IUnlockCallback(msg.sender).unlockCallback(data)`
    function unlock(bytes calldata data) external returns (bytes memory);

    /// @notice Initialize the state for a given pool ID
    /// @dev A swap fee totaling MAX_SWAP_FEE (100%) makes exact output swaps impossible since the input is entirely consumed by the fee
    /// @param key The pool key for the pool to initialize
    /// @param sqrtPriceX96 The initial square root price
    /// @return tick The initial tick of the pool
    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick);

    /// @notice Modify the liquidity for the given pool
    /// @dev Poke by calling with a zero liquidityDelta
    /// @param key The pool to modify liquidity in
    /// @param params The parameters for modifying the liquidity
    /// @param hookData The data to pass through to the add/removeLiquidity hooks
    /// @return callerDelta The balance delta of the caller of modifyLiquidity. This is the total of both principal, fee deltas, and hook deltas if applicable
    /// @return feesAccrued The balance delta of the fees generated in the liquidity range. Returned for informational purposes
    /// @dev Note that feesAccrued can be artificially inflated by a malicious actor and integrators should be careful using the value
    /// For pools with a single liquidity position, actors can donate to themselves to inflate feeGrowthGlobal (and consequently feesAccrued)
    /// atomically donating and collecting fees in the same unlockCallback may make the inflated value more extreme
    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued);

    /// @notice Swap against the given pool
    /// @param key The pool to swap in
    /// @param params The parameters for swapping
    /// @param hookData The data to pass through to the swap hooks
    /// @return swapDelta The balance delta of the address swapping
    /// @dev Swapping on low liquidity pools may cause unexpected swap amounts when liquidity available is less than amountSpecified.
    /// Additionally note that if interacting with hooks that have the BEFORE_SWAP_RETURNS_DELTA_FLAG or AFTER_SWAP_RETURNS_DELTA_FLAG
    /// the hook may alter the swap input/output. Integrators should perform checks on the returned swapDelta.
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta);

    /// @notice Donate the given currency amounts to the in-range liquidity providers of a pool
    /// @dev Calls to donate can be frontrun adding just-in-time liquidity, with the aim of receiving a portion donated funds.
    /// Donors should keep this in mind when designing donation mechanisms.
    /// @dev This function donates to in-range LPs at slot0.tick. In certain edge-cases of the swap algorithm, the `sqrtPrice` of
    /// a pool can be at the lower boundary of tick `n`, but the `slot0.tick` of the pool is already `n - 1`. In this case a call to
    /// `donate` would donate to tick `n - 1` (slot0.tick) not tick `n` (getTickAtSqrtPrice(slot0.sqrtPriceX96)).
    /// Read the comments in `Pool.swap()` for more information about this.
    /// @param key The key of the pool to donate to
    /// @param amount0 The amount of currency0 to donate
    /// @param amount1 The amount of currency1 to donate
    /// @param hookData The data to pass through to the donate hooks
    /// @return BalanceDelta The delta of the caller after the donate
    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta);

    /// @notice Writes the current ERC20 balance of the specified currency to transient storage
    /// This is used to checkpoint balances for the manager and derive deltas for the caller.
    /// @dev This MUST be called before any ERC20 tokens are sent into the contract, but can be skipped
    /// for native tokens because the amount to settle is determined by the sent value.
    /// However, if an ERC20 token has been synced and not settled, and the caller instead wants to settle
    /// native funds, this function can be called with the native currency to then be able to settle the native currency
    function sync(Currency currency) external;

    /// @notice Called by the user to net out some value owed to the user
    /// @dev Will revert if the requested amount is not available, consider using `mint` instead
    /// @dev Can also be used as a mechanism for free flash loans
    /// @param currency The currency to withdraw from the pool manager
    /// @param to The address to withdraw to
    /// @param amount The amount of currency to withdraw
    function take(Currency currency, address to, uint256 amount) external;

    /// @notice Called by the user to pay what is owed
    /// @return paid The amount of currency settled
    function settle() external payable returns (uint256 paid);

    /// @notice Called by the user to pay on behalf of another address
    /// @param recipient The address to credit for the payment
    /// @return paid The amount of currency settled
    function settleFor(address recipient) external payable returns (uint256 paid);

    /// @notice WARNING - Any currency that is cleared, will be non-retrievable, and locked in the contract permanently.
    /// A call to clear will zero out a positive balance WITHOUT a corresponding transfer.
    /// @dev This could be used to clear a balance that is considered dust.
    /// Additionally, the amount must be the exact positive balance. This is to enforce that the caller is aware of the amount being cleared.
    function clear(Currency currency, uint256 amount) external;

    /// @notice Called by the user to move value into ERC6909 balance
    /// @param to The address to mint the tokens to
    /// @param id The currency address to mint to ERC6909s, as a uint256
    /// @param amount The amount of currency to mint
    /// @dev The id is converted to a uint160 to correspond to a currency address
    /// If the upper 12 bytes are not 0, they will be 0-ed out
    function mint(address to, uint256 id, uint256 amount) external;

    /// @notice Called by the user to move value from ERC6909 balance
    /// @param from The address to burn the tokens from
    /// @param id The currency address to burn from ERC6909s, as a uint256
    /// @param amount The amount of currency to burn
    /// @dev The id is converted to a uint160 to correspond to a currency address
    /// If the upper 12 bytes are not 0, they will be 0-ed out
    function burn(address from, uint256 id, uint256 amount) external;

    /// @notice Updates the pools lp fees for the a pool that has enabled dynamic lp fees.
    /// @dev A swap fee totaling MAX_SWAP_FEE (100%) makes exact output swaps impossible since the input is entirely consumed by the fee
    /// @param key The key of the pool to update dynamic LP fees for
    /// @param newDynamicLPFee The new dynamic pool LP fee
    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external;
}

// node_modules/@uniswap/v4-core/test/utils/CurrencySettler.sol

/// @notice Library used to interact with PoolManager.sol to settle any open deltas.
/// To settle a positive delta (a credit to the user), a user may take or mint.
/// To settle a negative delta (a debt on the user), a user make transfer or burn to pay off a debt.
/// @dev Note that sync() is called before any erc-20 transfer in `settle`.
library CurrencySettler {
    /// @notice Settle (pay) a currency to the PoolManager
    /// @param currency Currency to settle
    /// @param manager IPoolManager to settle to
    /// @param payer Address of the payer, the token sender
    /// @param amount Amount to send
    /// @param burn If true, burn the ERC-6909 token, otherwise ERC20-transfer to the PoolManager
    function settle(Currency currency, IPoolManager manager, address payer, uint256 amount, bool burn) internal {
        // for native currencies or burns, calling sync is not required
        // short circuit for ERC-6909 burns to support ERC-6909-wrapped native tokens
        if (burn) {
            manager.burn(payer, currency.toId(), amount);
        } else if (currency.isAddressZero()) {
            manager.settle{value: amount}();
        } else {
            manager.sync(currency);
            if (payer != address(this)) {
                IERC20Minimal(Currency.unwrap(currency)).transferFrom(payer, address(manager), amount);
            } else {
                IERC20Minimal(Currency.unwrap(currency)).transfer(address(manager), amount);
            }
            manager.settle();
        }
    }

    /// @notice Take (receive) a currency from the PoolManager
    /// @param currency Currency to take
    /// @param manager IPoolManager to take from
    /// @param recipient Address of the recipient, the token receiver
    /// @param amount Amount to receive
    /// @param claims If true, mint the ERC-6909 token, otherwise ERC20-transfer from the PoolManager to recipient
    function take(Currency currency, IPoolManager manager, address recipient, uint256 amount, bool claims) internal {
        claims ? manager.mint(recipient, currency.toId(), amount) : manager.take(currency, recipient, amount);
    }
}

// node_modules/@uniswap/v4-periphery/src/interfaces/IImmutableState.sol

/// @title IImmutableState
/// @notice Interface for the ImmutableState contract
interface IImmutableState {
    /// @notice The Uniswap v4 PoolManager contract
    function poolManager() external view returns (IPoolManager);
}

// node_modules/@uniswap/v4-periphery/src/base/ImmutableState.sol

/// @title Immutable State
/// @notice A collection of immutable state variables, commonly used across multiple contracts
contract ImmutableState is IImmutableState {
    /// @inheritdoc IImmutableState
    IPoolManager public immutable poolManager;

    /// @notice Thrown when the caller is not PoolManager
    error NotPoolManager();

    /// @notice Only allow calls from the PoolManager contract
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }
}

// node_modules/@uniswap/v4-core/src/libraries/Hooks.sol

/// @notice V4 decides whether to invoke specific hooks by inspecting the least significant bits
/// of the address that the hooks contract is deployed to.
/// For example, a hooks contract deployed to address: 0x0000000000000000000000000000000000002400
/// has the lowest bits '10 0100 0000 0000' which would cause the 'before initialize' and 'after add liquidity' hooks to be used.
library Hooks {
    using LPFeeLibrary for uint24;
    using Hooks for IHooks;
    using SafeCast for int256;
    using BeforeSwapDeltaLibrary for BeforeSwapDelta;
    using ParseBytes for bytes;
    using CustomRevert for bytes4;

    uint160 internal constant ALL_HOOK_MASK = uint160((1 << 14) - 1);

    uint160 internal constant BEFORE_INITIALIZE_FLAG = 1 << 13;
    uint160 internal constant AFTER_INITIALIZE_FLAG = 1 << 12;

    uint160 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 11;
    uint160 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 10;

    uint160 internal constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 9;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 8;

    uint160 internal constant BEFORE_SWAP_FLAG = 1 << 7;
    uint160 internal constant AFTER_SWAP_FLAG = 1 << 6;

    uint160 internal constant BEFORE_DONATE_FLAG = 1 << 5;
    uint160 internal constant AFTER_DONATE_FLAG = 1 << 4;

    uint160 internal constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 3;
    uint160 internal constant AFTER_SWAP_RETURNS_DELTA_FLAG = 1 << 2;
    uint160 internal constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 1;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 0;

    struct Permissions {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeAddLiquidity;
        bool afterAddLiquidity;
        bool beforeRemoveLiquidity;
        bool afterRemoveLiquidity;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
        bool beforeSwapReturnDelta;
        bool afterSwapReturnDelta;
        bool afterAddLiquidityReturnDelta;
        bool afterRemoveLiquidityReturnDelta;
    }

    /// @notice Thrown if the address will not lead to the specified hook calls being called
    /// @param hooks The address of the hooks contract
    error HookAddressNotValid(address hooks);

    /// @notice Hook did not return its selector
    error InvalidHookResponse();

    /// @notice Additional context for ERC-7751 wrapped error when a hook call fails
    error HookCallFailed();

    /// @notice The hook's delta changed the swap from exactIn to exactOut or vice versa
    error HookDeltaExceedsSwapAmount();

    /// @notice Utility function intended to be used in hook constructors to ensure
    /// the deployed hooks address causes the intended hooks to be called
    /// @param permissions The hooks that are intended to be called
    /// @dev permissions param is memory as the function will be called from constructors
    function validateHookPermissions(IHooks self, Permissions memory permissions) internal pure {
        if (
            permissions.beforeInitialize != self.hasPermission(BEFORE_INITIALIZE_FLAG)
                || permissions.afterInitialize != self.hasPermission(AFTER_INITIALIZE_FLAG)
                || permissions.beforeAddLiquidity != self.hasPermission(BEFORE_ADD_LIQUIDITY_FLAG)
                || permissions.afterAddLiquidity != self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG)
                || permissions.beforeRemoveLiquidity != self.hasPermission(BEFORE_REMOVE_LIQUIDITY_FLAG)
                || permissions.afterRemoveLiquidity != self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)
                || permissions.beforeSwap != self.hasPermission(BEFORE_SWAP_FLAG)
                || permissions.afterSwap != self.hasPermission(AFTER_SWAP_FLAG)
                || permissions.beforeDonate != self.hasPermission(BEFORE_DONATE_FLAG)
                || permissions.afterDonate != self.hasPermission(AFTER_DONATE_FLAG)
                || permissions.beforeSwapReturnDelta != self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)
                || permissions.afterSwapReturnDelta != self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)
                || permissions.afterAddLiquidityReturnDelta != self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
                || permissions.afterRemoveLiquidityReturnDelta
                    != self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
        ) {
            HookAddressNotValid.selector.revertWith(address(self));
        }
    }

    /// @notice Ensures that the hook address includes at least one hook flag or dynamic fees, or is the 0 address
    /// @param self The hook to verify
    /// @param fee The fee of the pool the hook is used with
    /// @return bool True if the hook address is valid
    function isValidHookAddress(IHooks self, uint24 fee) internal pure returns (bool) {
        // The hook can only have a flag to return a hook delta on an action if it also has the corresponding action flag
        if (!self.hasPermission(BEFORE_SWAP_FLAG) && self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)) return false;
        if (!self.hasPermission(AFTER_SWAP_FLAG) && self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)) return false;
        if (!self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG) && self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG))
        {
            return false;
        }
        if (
            !self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)
                && self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
        ) return false;

        // If there is no hook contract set, then fee cannot be dynamic
        // If a hook contract is set, it must have at least 1 flag set, or have a dynamic fee
        return address(self) == address(0)
            ? !fee.isDynamicFee()
            : (uint160(address(self)) & ALL_HOOK_MASK > 0 || fee.isDynamicFee());
    }

    /// @notice performs a hook call using the given calldata on the given hook that doesn't return a delta
    /// @return result The complete data returned by the hook
    function callHook(IHooks self, bytes memory data) internal returns (bytes memory result) {
        bool success;
        assembly ("memory-safe") {
            success := call(gas(), self, 0, add(data, 0x20), mload(data), 0, 0)
        }
        // Revert with FailedHookCall, containing any error message to bubble up
        if (!success) CustomRevert.bubbleUpAndRevertWith(address(self), bytes4(data), HookCallFailed.selector);

        // The call was successful, fetch the returned data
        assembly ("memory-safe") {
            // allocate result byte array from the free memory pointer
            result := mload(0x40)
            // store new free memory pointer at the end of the array padded to 32 bytes
            mstore(0x40, add(result, and(add(returndatasize(), 0x3f), not(0x1f))))
            // store length in memory
            mstore(result, returndatasize())
            // copy return data to result
            returndatacopy(add(result, 0x20), 0, returndatasize())
        }

        // Length must be at least 32 to contain the selector. Check expected selector and returned selector match.
        if (result.length < 32 || result.parseSelector() != data.parseSelector()) {
            InvalidHookResponse.selector.revertWith();
        }
    }

    /// @notice performs a hook call using the given calldata on the given hook
    /// @return int256 The delta returned by the hook
    function callHookWithReturnDelta(IHooks self, bytes memory data, bool parseReturn) internal returns (int256) {
        bytes memory result = callHook(self, data);

        // If this hook wasn't meant to return something, default to 0 delta
        if (!parseReturn) return 0;

        // A length of 64 bytes is required to return a bytes4, and a 32 byte delta
        if (result.length != 64) InvalidHookResponse.selector.revertWith();
        return result.parseReturnDelta();
    }

    /// @notice modifier to prevent calling a hook if they initiated the action
    modifier noSelfCall(IHooks self) {
        if (msg.sender != address(self)) {
            _;
        }
    }

    /// @notice calls beforeInitialize hook if permissioned and validates return value
    function beforeInitialize(IHooks self, PoolKey memory key, uint160 sqrtPriceX96) internal noSelfCall(self) {
        if (self.hasPermission(BEFORE_INITIALIZE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeInitialize, (msg.sender, key, sqrtPriceX96)));
        }
    }

    /// @notice calls afterInitialize hook if permissioned and validates return value
    function afterInitialize(IHooks self, PoolKey memory key, uint160 sqrtPriceX96, int24 tick)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(AFTER_INITIALIZE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.afterInitialize, (msg.sender, key, sqrtPriceX96, tick)));
        }
    }

    /// @notice calls beforeModifyLiquidity hook if permissioned and validates return value
    function beforeModifyLiquidity(
        IHooks self,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) internal noSelfCall(self) {
        if (params.liquidityDelta > 0 && self.hasPermission(BEFORE_ADD_LIQUIDITY_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeAddLiquidity, (msg.sender, key, params, hookData)));
        } else if (params.liquidityDelta <= 0 && self.hasPermission(BEFORE_REMOVE_LIQUIDITY_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeRemoveLiquidity, (msg.sender, key, params, hookData)));
        }
    }

    /// @notice calls afterModifyLiquidity hook if permissioned and validates return value
    function afterModifyLiquidity(
        IHooks self,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal returns (BalanceDelta callerDelta, BalanceDelta hookDelta) {
        if (msg.sender == address(self)) return (delta, BalanceDeltaLibrary.ZERO_DELTA);

        callerDelta = delta;
        if (params.liquidityDelta > 0) {
            if (self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG)) {
                hookDelta = BalanceDelta.wrap(
                    self.callHookWithReturnDelta(
                        abi.encodeCall(
                            IHooks.afterAddLiquidity, (msg.sender, key, params, delta, feesAccrued, hookData)
                        ),
                        self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
                    )
                );
                callerDelta = callerDelta - hookDelta;
            }
        } else {
            if (self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)) {
                hookDelta = BalanceDelta.wrap(
                    self.callHookWithReturnDelta(
                        abi.encodeCall(
                            IHooks.afterRemoveLiquidity, (msg.sender, key, params, delta, feesAccrued, hookData)
                        ),
                        self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
                    )
                );
                callerDelta = callerDelta - hookDelta;
            }
        }
    }

    /// @notice calls beforeSwap hook if permissioned and validates return value
    function beforeSwap(IHooks self, PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        internal
        returns (int256 amountToSwap, BeforeSwapDelta hookReturn, uint24 lpFeeOverride)
    {
        amountToSwap = params.amountSpecified;
        if (msg.sender == address(self)) return (amountToSwap, BeforeSwapDeltaLibrary.ZERO_DELTA, lpFeeOverride);

        if (self.hasPermission(BEFORE_SWAP_FLAG)) {
            bytes memory result = callHook(self, abi.encodeCall(IHooks.beforeSwap, (msg.sender, key, params, hookData)));

            // A length of 96 bytes is required to return a bytes4, a 32 byte delta, and an LP fee
            if (result.length != 96) InvalidHookResponse.selector.revertWith();

            // dynamic fee pools that want to override the cache fee, return a valid fee with the override flag. If override flag
            // is set but an invalid fee is returned, the transaction will revert. Otherwise the current LP fee will be used
            if (key.fee.isDynamicFee()) lpFeeOverride = result.parseFee();

            // skip this logic for the case where the hook return is 0
            if (self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)) {
                hookReturn = BeforeSwapDelta.wrap(result.parseReturnDelta());

                // any return in unspecified is passed to the afterSwap hook for handling
                int128 hookDeltaSpecified = hookReturn.getSpecifiedDelta();

                // Update the swap amount according to the hook's return, and check that the swap type doesn't change (exact input/output)
                if (hookDeltaSpecified != 0) {
                    bool exactInput = amountToSwap < 0;
                    amountToSwap += hookDeltaSpecified;
                    if (exactInput ? amountToSwap > 0 : amountToSwap < 0) {
                        HookDeltaExceedsSwapAmount.selector.revertWith();
                    }
                }
            }
        }
    }

    /// @notice calls afterSwap hook if permissioned and validates return value
    function afterSwap(
        IHooks self,
        PoolKey memory key,
        SwapParams memory params,
        BalanceDelta swapDelta,
        bytes calldata hookData,
        BeforeSwapDelta beforeSwapHookReturn
    ) internal returns (BalanceDelta, BalanceDelta) {
        if (msg.sender == address(self)) return (swapDelta, BalanceDeltaLibrary.ZERO_DELTA);

        int128 hookDeltaSpecified = beforeSwapHookReturn.getSpecifiedDelta();
        int128 hookDeltaUnspecified = beforeSwapHookReturn.getUnspecifiedDelta();

        if (self.hasPermission(AFTER_SWAP_FLAG)) {
            hookDeltaUnspecified += self.callHookWithReturnDelta(
                abi.encodeCall(IHooks.afterSwap, (msg.sender, key, params, swapDelta, hookData)),
                self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)
            ).toInt128();
        }

        BalanceDelta hookDelta;
        if (hookDeltaUnspecified != 0 || hookDeltaSpecified != 0) {
            hookDelta = (params.amountSpecified < 0 == params.zeroForOne)
                ? toBalanceDelta(hookDeltaSpecified, hookDeltaUnspecified)
                : toBalanceDelta(hookDeltaUnspecified, hookDeltaSpecified);

            // the caller has to pay for (or receive) the hook's delta
            swapDelta = swapDelta - hookDelta;
        }
        return (swapDelta, hookDelta);
    }

    /// @notice calls beforeDonate hook if permissioned and validates return value
    function beforeDonate(IHooks self, PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(BEFORE_DONATE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeDonate, (msg.sender, key, amount0, amount1, hookData)));
        }
    }

    /// @notice calls afterDonate hook if permissioned and validates return value
    function afterDonate(IHooks self, PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(AFTER_DONATE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.afterDonate, (msg.sender, key, amount0, amount1, hookData)));
        }
    }

    function hasPermission(IHooks self, uint160 flag) internal pure returns (bool) {
        return uint160(address(self)) & flag != 0;
    }
}

// node_modules/@uniswap/v4-periphery/src/utils/BaseHook.sol

/// @title Base Hook
/// @notice abstract contract for hook implementations
abstract contract BaseHook is IHooks, ImmutableState {
    error HookNotImplemented();

    constructor(IPoolManager _manager) ImmutableState(_manager) {
        validateHookAddress(this);
    }

    /// @notice Returns a struct of permissions to signal which hook functions are to be implemented
    /// @dev Used at deployment to validate the address correctly represents the expected permissions
    /// @return Permissions struct
    function getHookPermissions() public pure virtual returns (Hooks.Permissions memory);

    /// @notice Validates the deployed hook address agrees with the expected permissions of the hook
    /// @dev this function is virtual so that we can override it during testing,
    /// which allows us to deploy an implementation to any address
    /// and then etch the bytecode into the correct address
    function validateHookAddress(BaseHook _this) internal pure virtual {
        Hooks.validateHookPermissions(_this, getHookPermissions());
    }

    /// @inheritdoc IHooks
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external
        onlyPoolManager
        returns (bytes4)
    {
        return _beforeInitialize(sender, key, sqrtPriceX96);
    }

    function _beforeInitialize(address, PoolKey calldata, uint160) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        onlyPoolManager
        returns (bytes4)
    {
        return _afterInitialize(sender, key, sqrtPriceX96, tick);
    }

    function _afterInitialize(address, PoolKey calldata, uint160, int24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeAddLiquidity(sender, key, params, hookData);
    }

    function _beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function _beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterRemoveLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        return _beforeSwap(sender, key, params, hookData);
    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeDonate(sender, key, amount0, amount1, hookData);
    }

    function _beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _afterDonate(sender, key, amount0, amount1, hookData);
    }

    function _afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}

// packages/fhevm-hardhat-template/contracts/UniversalPrivacyHook.sol

/**
 * @title UniversalPrivacyHook
 * @dev A Uniswap V4 hook that enables private swaps on any pool using FHE encrypted tokens
 * 
 * This hook can be attached to any Uniswap V4 pool to provide:
 * - Private swap intents with encrypted amounts and directions
 * - Automatic creation of hybrid FHE/ERC20 tokens per pool currency
 * - Batched execution for enhanced privacy
 * - 1:1 backing of encrypted tokens with hook reserves
 * 
 * Architecture:
 * - Users deposit ERC20 tokens → receive hybrid FHE/ERC20 tokens
 * - Users submit encrypted swap intents (amount + direction private)
 * - Hook processes intents by swapping its reserves and updating encrypted balances
 * - Users can withdraw or transfer their hybrid tokens freely
 */

// Uniswap V4 Imports

// Privacy Components

// Token & Security

// FHE - Zama FHEVM

contract UniversalPrivacyHook is BaseHook, IUnlockCallback, ReentrancyGuardTransient, SepoliaConfig {

    // =============================================================
    //                           EVENTS
    // =============================================================
    
    event EncryptedTokenCreated(PoolId indexed poolId, Currency indexed currency, address token);
    event Deposited(PoolId indexed poolId, Currency indexed currency, address indexed user, uint256 amount, address encryptedToken);
    event IntentSubmitted(PoolId indexed poolId, Currency tokenIn, Currency tokenOut, address indexed user, bytes32 intentId);
    event Withdrawn(PoolId indexed poolId, Currency indexed currency, address indexed user, address recipient, uint256 amount);

    // AVS Batch Events
    event BatchCreated(bytes32 indexed batchId, PoolId indexed poolId, uint256 intentCount);
    event BatchFinalized(bytes32 indexed batchId, uint256 intentCount);
    event BatchSettled(bytes32 indexed batchId);
    event BatchExecuted(bytes32 indexed batchId, uint128 netAmountIn, uint128 netAmountOut);

    // =============================================================
    //                          LIBRARIES
    // =============================================================
    
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;

    // =============================================================
    //                          STRUCTS
    // =============================================================
    
    /**
     * @dev Represents an encrypted swap intent
     */
    struct Intent {
        euint128 encAmount;      // Encrypted amount to swap
        Currency tokenIn;        // Input currency (currency0 or currency1)
        Currency tokenOut;       // Output currency (currency1 or currency0)
        address owner;           // User who submitted the intent
        uint64 deadline;         // Expiration timestamp
        bool processed;          // Whether intent has been executed
        PoolKey poolKey;         // Pool key for the swap
        bytes32 batchId;         // Batch this intent belongs to
    }

    /**
     * @dev Batch of intents for AVS processing
     */
    struct Batch {
        bytes32[] intentIds;     // Intent IDs in this batch
        uint256 createdBlock;    // Block when batch was created
        uint256 submittedBlock;  // Block when batch was submitted to AVS
        bool finalized;          // Whether batch has been finalized
        bool settled;            // Whether batch has been settled
    }

    // =============================================================
    //                         CONSTANTS
    // =============================================================
    
    bytes internal constant ZERO_BYTES = bytes("");
    
    // FHE encrypted constants for reuse - removed as they're not used

    // =============================================================
    //                      STATE VARIABLES
    // =============================================================

    /// @dev Per-pool encrypted token contracts: poolId => currency => IFHERC20
    mapping(PoolId => mapping(Currency => IFHERC20)) public poolEncryptedTokens;

    /// @dev Per-pool reserves backing encrypted tokens: poolId => currency => amount
    mapping(PoolId => mapping(Currency => uint256)) public poolReserves;

    /// @dev Global intent storage: intentId => Intent
    mapping(bytes32 => Intent) public intents;

    // AVS Batch Management
    /// @dev Batch interval in blocks (5 blocks = ~5-60 seconds depending on chain)
    uint256 public constant BATCH_INTERVAL = 5;

    /// @dev Current batch ID per pool
    mapping(PoolId => bytes32) public currentBatchId;

    /// @dev Batch storage
    mapping(bytes32 => Batch) public batches;

    /// @dev SwapManager address for AVS integration
    address public swapManager;

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        // No FHE initialization needed in constructor
        // FHE operations will be done when actually needed
    }

    /**
     * @dev Set the SwapManager address (only once)
     * @param _swapManager Address of the AVS SwapManager contract
     */
    function setSwapManager(address _swapManager) external {
        require(_swapManager != address(0), "Invalid address");
        swapManager = _swapManager;
    }

    // =============================================================
    //                      HOOK CONFIGURATION
    // =============================================================
    
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,                    // Process encrypted intents
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // =============================================================
    //                      CORE FUNCTIONS
    // =============================================================
    
    /**
     * @dev Deposit tokens to receive encrypted tokens for a specific pool
     * @param key The pool key identifying the pool
     * @param currency The currency to deposit (must be currency0 or currency1)
     * @param amount The amount to deposit
     */
    function deposit(
        PoolKey calldata key,
        Currency currency,
        uint256 amount
    ) external nonReentrant {
        PoolId poolId = key.toId();
        
        // Validate hook is enabled for this pool
        require(address(key.hooks) == address(this), "Hook not enabled");

        // Validate currency belongs to this pool
        require(currency == key.currency0 || currency == key.currency1, "Invalid currency");
        
        // Get or create encrypted token for this pool/currency
        IFHERC20 encryptedToken = _getOrCreateEncryptedToken(poolId, currency);
        
        // Transfer tokens from user to hook
        IERC20(Currency.unwrap(currency)).transferFrom(msg.sender, address(this), amount);
        
        // Mint encrypted tokens to user using trivial encryption
        euint128 encryptedAmount = FHE.asEuint128(uint128(amount));
        FHE.allowThis(encryptedAmount);
        FHE.allow(encryptedAmount, address(encryptedToken));
        encryptedToken.mintEncrypted(msg.sender, encryptedAmount);
        
        // Update hook reserves
        poolReserves[poolId][currency] += amount;

        emit Deposited(poolId, currency, msg.sender, amount, address(encryptedToken));
    }
    
    /**
     * @dev Submit an encrypted swap intent
     * TODO: Move intent submission logic to separate IntentManager contract
     * This will allow supporting multiple intent types (swapIntent, tradeIntent, limitIntent)
     * IntentManager will be the entry point but hook must always hold the funds
     * @param key The pool key
     * @param tokenIn Input currency
     * @param tokenOut Output currency
     * @param encAmount Encrypted amount to swap
     * @param deadline Intent expiration
     */
    function submitIntent(
        PoolKey calldata key,
        Currency tokenIn,
        Currency tokenOut,
        externalEuint128 encAmount,
        bytes calldata inputProof,
        uint64 deadline
    ) external nonReentrant {
        PoolId poolId = key.toId();

        // Validate currencies form valid pair for this pool
        require((tokenIn == key.currency0 && tokenOut == key.currency1) ||
                (tokenIn == key.currency1 && tokenOut == key.currency0), "Invalid pair");

        // Convert to euint128 and set up proper FHE access control
        euint128 amount = FHE.fromExternal(encAmount, inputProof);
        FHE.allowThis(amount);

        // User transfers encrypted tokens to hook as collateral
        IFHERC20 inputToken = poolEncryptedTokens[poolId][tokenIn];
        require(address(inputToken) != address(0), "Token not exists");

        // Grant token contract access to the encrypted amount
        FHE.allow(amount, address(inputToken));

        // Transfer encrypted tokens from user to hook as collateral
        inputToken.transferFromEncrypted(msg.sender, address(this), amount);

        // Check and create/update batch
        bytes32 batchId = currentBatchId[poolId];
        Batch storage batch = batches[batchId];

        // Create new batch if needed (first batch or interval passed)
        if (batchId == bytes32(0) || block.number >= batch.createdBlock + BATCH_INTERVAL) {
            // Finalize the previous batch if it exists and has intents
            if (batchId != bytes32(0) && batch.intentIds.length > 0 && !batch.finalized) {
                _finalizeBatch(poolId, batchId);
            }

            // Create new batch
            batchId = keccak256(abi.encode(poolId, block.number, block.timestamp));
            currentBatchId[poolId] = batchId;
            batches[batchId] = Batch({
                intentIds: new bytes32[](0),
                createdBlock: block.number,
                submittedBlock: 0,
                finalized: false,
                settled: false
            });
            batch = batches[batchId];
        }

        // Create and store intent
        bytes32 intentId = keccak256(abi.encode(msg.sender, block.timestamp, poolId));
        intents[intentId] = Intent({
            encAmount: amount,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            owner: msg.sender,
            deadline: deadline,
            processed: false,
            poolKey: key,
            batchId: batchId
        });

        // Add intent to current batch
        batch.intentIds.push(intentId);

        emit IntentSubmitted(poolId, tokenIn, tokenOut, msg.sender, intentId);
    }
    
    /**
     * @dev Withdraw encrypted tokens back to underlying ERC20
     * @param key The pool key
     * @param currency The currency to withdraw
     * @param amount The amount to withdraw
     * @param recipient The recipient address
     */
    function withdraw(
        PoolKey calldata key,
        Currency currency,
        uint256 amount,
        address recipient
    ) external nonReentrant {
        PoolId poolId = key.toId();
        
        // Get encrypted token contract
        IFHERC20 encryptedToken = poolEncryptedTokens[poolId][currency];
        require(address(encryptedToken) != address(0), "Token not exists");
        
        // Create encrypted amount for burning
        euint128 encryptedAmount = FHE.asEuint128(uint128(amount));
        FHE.allowThis(encryptedAmount);
        FHE.allow(encryptedAmount, address(encryptedToken));
        
        // Burn encrypted tokens from user
        encryptedToken.burnEncrypted(msg.sender, encryptedAmount);
        
        // Update reserves
        poolReserves[poolId][currency] -= amount;
        
        // Transfer underlying tokens to recipient
        IERC20(Currency.unwrap(currency)).transfer(recipient, amount);
        
        emit Withdrawn(poolId, currency, msg.sender, recipient, amount);
    }

    // =============================================================
    //                     HOOK IMPLEMENTATIONS
    // =============================================================
    
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata data
    ) internal override onlyPoolManager() returns (bytes4, BeforeSwapDelta, uint24) {
        
        // Allow hook-initiated swaps to pass through
        if (sender == address(this)) {
            return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        }
        // For privacy, we could block external swaps or allow them
        // For now, let's allow external swaps but process intents first
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    
    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================
    
    function _getOrCreateEncryptedToken(PoolId poolId, Currency currency) internal returns (IFHERC20) {
        IFHERC20 existing = poolEncryptedTokens[poolId][currency];
        
        if (address(existing) == address(0)) {
            // Create new hybrid FHE/ERC20 token
            string memory symbol = _getCurrencySymbol(currency);
            string memory name = string(abi.encodePacked("Encrypted ", symbol));
            uint8 decimals = IERC20Metadata(Currency.unwrap(currency)).decimals();
            
            existing = new HybridFHERC20(name, string(abi.encodePacked("e", symbol)), decimals);
            poolEncryptedTokens[poolId][currency] = existing;
            
            emit EncryptedTokenCreated(poolId, currency, address(existing));
        }
        
        return existing;
    }
    
    function _getCurrencySymbol(Currency currency) internal view returns (string memory) {
        // Try to get the symbol from the ERC20 token
        try IERC20Metadata(Currency.unwrap(currency)).symbol() returns (string memory symbol) {
            return symbol;
        } catch {
            // Fallback if token doesn't implement symbol()
            return "TOKEN";
        }
    }
    
    // =============================================================
    //                    BATCH MANAGEMENT
    // =============================================================

    /**
     * @dev Finalize a batch and submit to AVS for processing (external callable)
     * @param poolId The pool ID to finalize batch for
     */
    function finalizeBatch(PoolId poolId) external {
        bytes32 batchId = currentBatchId[poolId];
        require(batchId != bytes32(0), "No active batch");

        Batch storage batch = batches[batchId];
        require(!batch.finalized, "Already finalized");
        require(block.number >= batch.createdBlock + BATCH_INTERVAL, "Batch not ready");
        require(batch.intentIds.length > 0, "Empty batch");

        _finalizeBatch(poolId, batchId);
    }

    /**
     * @dev Internal function to finalize a batch
     * @param poolId The pool ID
     * @param batchId The batch ID to finalize
     */
    function _finalizeBatch(PoolId poolId, bytes32 batchId) internal {
        Batch storage batch = batches[batchId];

        // Mark as finalized
        batch.finalized = true;
        batch.submittedBlock = block.number;

        // Package batch data for AVS
        bytes[] memory encryptedIntents = new bytes[](batch.intentIds.length);

        for (uint i = 0; i < batch.intentIds.length; i++) {
            Intent storage intent = intents[batch.intentIds[i]];

            // Package intent data for AVS
            encryptedIntents[i] = abi.encode(
                batch.intentIds[i],
                intent.owner,
                intent.tokenIn,
                intent.tokenOut,
                euint128.unwrap(intent.encAmount), // Pass the encrypted handle
                intent.deadline
            );
            FHE.allowTransient(intent.encAmount, swapManager);
        }

        // Submit to AVS SwapManager
        if (swapManager != address(0)) {
            bytes memory batchData = abi.encode(
                batchId,
                batch.intentIds,
                poolId,
                address(this),
                encryptedIntents
            );

            ISwapManager(swapManager).finalizeBatch(batchId, batchData);
        }

        // Start new batch for the pool
        currentBatchId[poolId] = bytes32(0);

        emit BatchCreated(batchId, poolId, batch.intentIds.length);
        emit BatchFinalized(batchId, batch.intentIds.length);
    }

    // Settlement structures for AVS
    struct InternalTransfer {
        address to;             // User receiving tokens
        address encToken;       // IFHERC20 token address (e.g., eUSDC or eUSDT contract)
        bytes32 encAmount;      // External encrypted amount handle from AVS (will be verified via FHE.fromExternal)
    }

    struct UserShare {
        address user;           // User address
        uint128 shareNumerator; // User's share numerator (e.g., 4 for 4/5)
        uint128 shareDenominator; // Share denominator (e.g., 5 for 4/5)
    }

    // State variable to track AMM output for distribution
    uint128 private lastSwapOutput;

    /**
     * @dev Settle a batch with internal transfers and net swaps from AVS
     * @param batchId The batch ID to settle
     * @param internalTransfers Internal transfers to users (only minting since hook holds tokens)
     * @param netAmountIn Total amount to swap in AMM (unencrypted)
     * @param tokenIn Input currency for AMM swap (pool token)
     * @param tokenOut Output currency for AMM swap (pool token)
     * @param outputToken IFHERC20 token address for output distribution
     * @param userShares How to distribute AMM output among users (as ratios)
     */
    function settleBatch(
        bytes32 batchId,
        InternalTransfer[] calldata internalTransfers,
        uint128 netAmountIn,
        Currency tokenIn,
        Currency tokenOut,
        address outputToken,
        UserShare[] calldata userShares,
        bytes calldata inputProof
    ) external {
        // TODO: Add onlySwapManager modifier once SwapManager interface is added
        require(swapManager != address(0), "SwapManager not set");
        require(msg.sender == swapManager, "Only SwapManager");

        Batch storage batch = batches[batchId];
        require(batch.finalized, "Batch not finalized");
        require(!batch.settled, "Already settled");

        // Get pool key from first intent
        Intent storage firstIntent = intents[batch.intentIds[0]];
        PoolKey memory key = firstIntent.poolKey;

        // Process internal transfers (hook already holds all tokens from intents)
        for (uint i = 0; i < internalTransfers.length; i++) {
            InternalTransfer memory transfer = internalTransfers[i];

            // Cast to IFHERC20 interface
            IFHERC20 encToken = IFHERC20(transfer.encToken);

            // Verify handle via FHE.fromExternal with inputProof
            // This converts external handle (bytes32) to verified internal euint128
            euint128 verifiedAmount = FHE.fromExternal(
                externalEuint128.wrap(transfer.encAmount),
                inputProof
            );

            // Grant permissions to encrypted token contract
            FHE.allow(verifiedAmount, address(encToken));

            // Transfer from Hook to receiver (Hook already holds tokens from matched intents)
            encToken.transferEncrypted(transfer.to, verifiedAmount);
        }

        // Execute net swap on AMM if needed
        if (netAmountIn > 0) {
            // Reset last swap output
            lastSwapOutput = 0;

            // Use unlock callback to execute the net swap
            bytes memory unlockData = abi.encode(
                key,
                batchId,
                netAmountIn,
                tokenIn,
                tokenOut,
                address(this)
            );

            poolManager.unlock(unlockData);

            // Now lastSwapOutput contains the actual amount received from AMM
            require(lastSwapOutput > 0, "Swap failed");

            // Distribute AMM output based on user shares
            IFHERC20 encOutputToken = IFHERC20(outputToken);

            for (uint i = 0; i < userShares.length; i++) {
                UserShare memory share = userShares[i];

                // Calculate user's portion: (lastSwapOutput * numerator) / denominator
                uint128 userAmount = (lastSwapOutput * share.shareNumerator) / share.shareDenominator;

                // Create encrypted amount and mint to user
                euint128 encAmount = FHE.asEuint128(userAmount);
                FHE.allowThis(encAmount);
                FHE.allow(encAmount, address(encOutputToken));

                encOutputToken.mintEncrypted(share.user, encAmount);
            }
        }

        // Mark batch as settled
        batch.settled = true;

        // Mark all intents as processed
        for (uint i = 0; i < batch.intentIds.length; i++) {
            intents[batch.intentIds[i]].processed = true;
        }

        emit BatchSettled(batchId);
    }

    // =============================================================
    //                      UNLOCK CALLBACK
    // =============================================================
    
    function unlockCallback(bytes calldata data) external override onlyPoolManager returns (bytes memory) {
        // Decode the batch settlement data (batchId instead of intentId for AVS settlement)
        (PoolKey memory key, bytes32 batchId, uint128 amount, Currency tokenIn, Currency tokenOut, address owner) =
            abi.decode(data, (PoolKey, bytes32, uint128, Currency, Currency, address));

        PoolId poolId = key.toId();
        
        // Determine swap direction
        bool zeroForOne = tokenIn == key.currency0;
        
        // Execute swap with EXACT INPUT (negative amount in V4)
        SwapParams memory swapParams = SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: -int256(uint256(amount)),  // Negative for exact input in V4
            sqrtPriceLimitX96: zeroForOne ? 
                TickMath.MIN_SQRT_PRICE + 1 : 
                TickMath.MAX_SQRT_PRICE - 1
        });
        
        BalanceDelta delta = poolManager.swap(key, swapParams, ZERO_BYTES);
        
        // Read signed deltas
        int128 d0 = delta.amount0();
        int128 d1 = delta.amount1();
        
        // Settle what we owe (negative), take what we're owed (positive)
        if (d0 < 0) {
            key.currency0.settle(poolManager, address(this), uint128(-d0), false);
        }
        if (d1 < 0) {
            key.currency1.settle(poolManager, address(this), uint128(-d1), false);
        }
        if (d0 > 0) {
            key.currency0.take(poolManager, address(this), uint128(d0), false);
        }
        if (d1 > 0) {
            key.currency1.take(poolManager, address(this), uint128(d1), false);
        }
        
        // Calculate output amount from the positive delta of the output currency
        uint128 outputAmount;
        if (tokenOut == key.currency0) {
            require(d0 > 0, "No token0 output");
            outputAmount = uint128(d0);
        } else {
            require(d1 > 0, "No token1 output");
            outputAmount = uint128(d1);
        }
        
        // Update hook reserves for batch net swap
        poolReserves[poolId][tokenIn] -= amount;
        poolReserves[poolId][tokenOut] += outputAmount;

        // Store the output amount for distribution in settleBatch
        lastSwapOutput = outputAmount;

        emit BatchExecuted(batchId, amount, outputAmount);

        return ZERO_BYTES;
    }
}

