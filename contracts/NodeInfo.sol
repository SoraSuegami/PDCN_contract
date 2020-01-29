pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature,Existence} from "./primitive.sol";

contract NodeInfo {
    Sha256 public node_id;
    Pubkey public pubkey;
    Sha256 public circuit_digest;
    address public owner;
    Existence public exist;

    constructor(Pubkey _pubkey, Sha256 _circuit_digest, address _owner) public {
        require(_owner!=address(0),"the address is zero");
        node_id = new Sha256(bytes32(0)).generate(abi.encode(_pubkey.pubkey,_circuit_digest.digest,_owner));
        pubkey = _pubkey;
        circuit_digest = _circuit_digest;
        owner = _owner;
    }

    function getPubkey() view public returns (Pubkey) {
        return pubkey;
    }

    function verify_signature(Sha256 _hash, Signature _witness) view public returns (bool) {
        address _signer = pubkey.to_address();
        return _witness.verify(_hash,_signer);
    }
}