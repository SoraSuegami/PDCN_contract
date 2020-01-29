pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature,Existence} from "./primitive.sol";
import {NodeInfo} from "./NodeInfo.sol";

contract Propagation {
    Sha256 parent_id;
    Pubkey pubkey;
    Sha256 circuit_digest;
    address owner;
    Signature witness;
    Existence public exist;

    constructor(Sha256 _parent_id, Pubkey _pubkey, Sha256 _circuit_digest, address _owner, Signature _witness) public {
        require(_owner!=address(0),"the address is zero");
        parent_id = _parent_id;
        pubkey = _pubkey;
        circuit_digest = _circuit_digest;
        owner = _owner;
        witness = _witness;
    }

    function digest() public returns (Sha256) {
        return new Sha256(bytes32(0)).generate(abi.encode(parent_id.digest,pubkey.pubkey,circuit_digest.digest));
    }

    function verify(NodeInfo _node_info) public returns (bool) {
        Sha256 _hash = digest();
        return _node_info.verify_signature(_hash,witness);
    }

    function child_node_info() public returns (NodeInfo) {
        return new NodeInfo(pubkey,circuit_digest,owner);
    }
}
