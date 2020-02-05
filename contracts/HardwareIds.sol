pragma solidity >=0.5.1;

import "./DeviceManager.sol";

contract HardwareIds {
    DeviceManager DM;

    constructor(address _dm_address) public {
        DM = DeviceManager(_dm_address);
    }

}