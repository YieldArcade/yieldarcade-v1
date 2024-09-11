// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { Owned } from "@solmate/auth/Owned.sol";

contract Registry is Owned {
    /// @notice Emitted when a new contract is registered.
    /// @param id value representing the unique ID tied to the new contract
    /// @param newContract address of the new contract
    event Registered(uint256 indexed id, address indexed newContract);

    /// @notice Emitted when the address of a contract is changed.
    /// @param id value representing the unique ID tied to the changed contract
    /// @param oldAddress address of the contract before the change
    /// @param newAddress address of the contract after the contract
    event AddressChanged(uint256 indexed id, address oldAddress, address newAddress);

    /// @notice Attempted to set the address of a contract that is not registered.
    /// @param id id of the contract that is not registered
    error Registry__ContractNotRegistered(uint256 id);

    /// @notice Attempted to trust an adaptor with non unique identifier.
    error Registry__IdentifierNotUnique();

    ///  @notice Attempted to use an untrusted adaptor.
    error Registry__AdaptorNotTrusted(address adaptor);

    /// @notice Attempted to trust an already trusted adaptor.
    error Registry__AdaptorAlreadyTrusted(address adaptor);

    /// @notice The unique ID that the next registered contract will have.
    uint256 public nextId;

    /// @notice Get the address associated with an id.
    mapping(uint256 => address) public getAddress;

    /// @notice Maps an adaptor address to bool indicating whether it has been set up in the registry.
    mapping(address => bool) public isAdaptorTrusted;

    /// @notice Maps an adaptors identfier to bool, to track if the identifier is unique wrt the registry.
    mapping(bytes32 => bool) public isIdentifierUsed;

    constructor(address newOwner, address priceRouter) Owned(newOwner) {
        _register(priceRouter);
    }

    /// @notice Set the address of the contract at a given id.
    function setAddress(uint256 id, address newAddress) external onlyOwner {
        if (id >= nextId) revert Registry__ContractNotRegistered(id);

        emit AddressChanged(id, getAddress[id], newAddress);

        getAddress[id] = newAddress;
    }

    /// @notice Register the address of a new contract.
    /// @param newContract address of the new contract to register
    function register(address newContract) external onlyOwner {
        _register(newContract);
    }

    /// @notice Trust an adaptor to be used by cellars
    /// @param adaptor address of the adaptor to trust
    function trustAdaptor(address adaptor) external onlyOwner {
        if (isAdaptorTrusted[adaptor]) revert Registry__AdaptorAlreadyTrusted(adaptor);
        bytes32 identifier = 0x0000000000000000000000000000000000000000000000000000000000080706; // BaseAdaptor(adaptor).identifier();
        if (isIdentifierUsed[identifier]) revert Registry__IdentifierNotUnique();
        isAdaptorTrusted[adaptor] = true;
        isIdentifierUsed[identifier] = true;
    }

    /// @notice Allows registry to distrust adaptors.
    /// @dev Doing so prevents Cellars from adding this adaptor to their catalogue.
    function distrustAdaptor(address adaptor) external onlyOwner {
        if (!isAdaptorTrusted[adaptor]) revert Registry__AdaptorNotTrusted(adaptor);
        // Set trust to false.
        isAdaptorTrusted[adaptor] = false;

        // We are NOT resetting `isIdentifierUsed` because if this adaptor is distrusted, then something needs
        // to change about the new one being re-trusted.
    }

    /// @notice Reverts if `adaptor` is not trusted by the registry.
    function revertIfAdaptorIsNotTrusted(address adaptor) external view {
        if (!isAdaptorTrusted[adaptor]) revert Registry__AdaptorNotTrusted(adaptor);
    }

    function _register(address newContract) internal {
        getAddress[nextId] = newContract;

        emit Registered(nextId, newContract);

        nextId++;
    }
}
