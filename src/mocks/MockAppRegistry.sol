// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IAppRegistry} from "../interfaces/IAppRegistry.sol";

contract MockAppRegistry is IAppRegistry {
    mapping(address => AppRegistrationStatus) private registrationStatus;
    mapping(address => string) private metadataURIs;

    function registerApp(address app, bytes memory, bytes32, uint256) external {
        registrationStatus[app] = AppRegistrationStatus.REGISTERED;
        emit AppRegistrationStatusUpdated(
            app,
            AppRegistrationStatus.REGISTERED
        );
    }

    function deregisterApp(address app) external {
        registrationStatus[app] = AppRegistrationStatus.UNREGISTERED;
        emit AppRegistrationStatusUpdated(
            app,
            AppRegistrationStatus.UNREGISTERED
        );
    }

    function isAppRegistered(address app) external view returns (bool) {
        return registrationStatus[app] == AppRegistrationStatus.REGISTERED;
    }

    function cancelSalt(bytes32) external pure {}

    function updateAppMetadataURI(string calldata metadataURI) external {
        metadataURIs[msg.sender] = metadataURI;
        emit AppMetadataURIUpdated(msg.sender, metadataURI);
    }

    function calculateAppRegistrationDigestHash(
        address,
        bytes32,
        uint256
    ) external pure returns (bytes32) {
        return bytes32(0);
    }
}
