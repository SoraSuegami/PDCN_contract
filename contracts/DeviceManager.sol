pragma solidity >=0.5.1;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/Counters.sol";
import {HardwareIds} from "./HardwareIds.sol";

contract DeviceManager is ERC721Full, ERC721Mintable, ERC721Burnable, ERC721Holder {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping (uint256 => string) public uri_of_deviceId;
    mapping (uint256 => uint256[]) public parts_of_deviceId;
    mapping (uint256 => uint256) public assembly_of_deviceId;
    Counters.Counter private counter = Counters.Counter(0);

    event Produce (
        address indexed owner,
        uint256 indexed device_id
    );

    event Assemble (
        address indexed owner,
        uint256 indexed device_id,
        uint256[] parts
    );

    event Disassemble (
        address indexed owner,
        uint256 indexed device_id
    );

    event Dispose (
        address indexed owner,
        uint256 indexed device_id
    );

    constructor() ERC721Full("Device", "DEVICE") public {}

    function getCounter() public view returns(uint256) {
        return counter.current();
    }

    function produce(string memory uri) public returns(uint256) {
        uint256 device_id = _update_id();
        require(device_id!=0,"token id is zero.");
        bool success = safeMint(msg.sender,device_id);
        require(success,"fail to mint device nft.");
        uri_of_deviceId[device_id] = uri;
        _setTokenURI(device_id, uri);
        emit Produce(msg.sender, device_id);
        return device_id;
    }

    function assemble(uint256[] memory parts, string memory uri) public returns(uint256) {
        uint len = parts.length;
        require(len>0,"the number of parts is zero.");
        uint i;
        for(i=0;i<len;i++){
            require(parts[i]!=0,"part token id is zero.");
            require(assembly_of_deviceId[parts[i]]==0,"the device is used for other assembled device");
            _remove(parts[i]);
        }
        uint256 device_id = produce(uri);
        require(device_id!=0,"assembled token id is zero.");
        require(msg.sender == ownerOf(device_id),"fail to produce assembled device nft.");
        parts_of_deviceId[device_id] = parts;
        for(i=0;i<len;i++){
            assembly_of_deviceId[parts[i]] = device_id;
        }
        emit Assemble(msg.sender,device_id,parts);
        return device_id;
    }

    function disassemble(uint256 device_id) public returns(uint256[] memory){
        require(device_id!=0,"given device id is zero.");
        require(assembly_of_deviceId[device_id]==0,"the device is used for assembled device");
        _remove(device_id);
        uint256[] memory parts = parts_of_deviceId[device_id];
        uint len = parts.length;
        uint i;
        for(i=0;i<len;i++){
            require(parts[i]!=0,"part token id is zero.");
            _recover(parts[i]);
            require(msg.sender == ownerOf(parts[i]),"fail to transfer part device nft.");
        }
        _reset(device_id);
        parts_of_deviceId[device_id] = new uint256[](0);
        for(i=0;i<len;i++){
            assembly_of_deviceId[parts[i]] = 0;
        }
        emit Disassemble(msg.sender,device_id);
        return parts;
    }

    function dispose(uint256 device_id) public {
        require(device_id!=0,"given device id is zero.");
        require(assembly_of_deviceId[device_id]==0,"the device is used for assembled device");
        if(parts_of_deviceId[device_id].length==0) {
            _remove(device_id);
            _reset(device_id);
            emit Dispose(msg.sender,device_id);
        }
        else {
            uint256[] memory parts = disassemble(device_id);
            uint i;
            for(i=0;i<parts.length;i++){
                dispose(parts[i]);
            }
        }
    }

    function _remove(uint256 device_id) private {
        burn(device_id);
        require(!_exists(device_id),"fail to burn device nft.");
    }

    function _recover(uint256 device_id) private {
        bool success = safeMint(msg.sender,device_id);
        require(success,"fail to mint device nft.");
        string memory uri = uri_of_deviceId[device_id];
        _setTokenURI(device_id, uri);
    }

    function _reset(uint256 device_id) private {
        uri_of_deviceId[device_id] = "";
    }

    function _update_id() private returns(uint256) {
        counter.increment();
        return counter.current();
    }
}
