pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature,Existence} from "./primitive.sol";

contract RequestInfo {
    address public client;
    uint256 public value;
    Sha256 public node_id;
    Sha256 public circuit_digest;
    Sha256 public input_digest;
    uint256 public expired;
    uint256 public nonce;
    Signature public witness;
    Existence public exist;

    constructor(address _client,uint256 _value,Sha256 _node_id,Sha256 _circuit_digest, Sha256 _input_digest, uint256 _expired, uint256 _nonce, Signature _witness) public {
        require(_client!=address(0),"the address is zero");
        client = _client;
        value = _value;
        node_id = _node_id;
        circuit_digest = _circuit_digest;
        input_digest = _input_digest;
        expired = _expired;
        nonce = _nonce;
        witness = _witness;
    }

    function digest() public returns (Sha256) {
        return new Sha256(bytes32(0)).generate(abi.encode(client,value,node_id.digest,circuit_digest.digest,input_digest.digest,expired,nonce));
    }

    function verify() public returns (bool) {
        Sha256 _hash = digest();
        return witness.verify(_hash,client);
    }
}
