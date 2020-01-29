pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature} from "./primitive.sol";
import {NodeInfo} from "./NodeInfo.sol";
import {RequestInfo} from "./RequestInfo.sol";
import {Propagation} from "./Propagation.sol";

contract NodeRegister {
    mapping(bytes32 => NodeInfo) public nodes;
    mapping(bytes32 => Propagation) public proofs;


    function register(Sha256 _parent_id, Pubkey _pubkey, Sha256 _circuit_digest, address _owner, Signature _witness) public {
        (bool parent_exist, NodeInfo parent) = search(_parent_id);
        require(parent_exist==true&&_parent_id==parent.node_id(),"the parent node does not exist");
        Propagation proof = new Propagation(_parent_id,_pubkey,_circuit_digest,_owner,_witness);
        require(proof.verify(parent),"invalid signature");
        NodeInfo child = new NodeInfo(_pubkey,_circuit_digest,_owner);
        Sha256 child_id = child.node_id();
        (bool child_exist,) = search(child_id);
        require(child_exist==false,"the child node already exists");
        require(proofs[child_id.digest()].exist().flag()==false,"the proof already exists");
        child.exist().add();
        proof.exist().add();
        nodes[child_id.digest()] = child;
        proofs[child_id.digest()] = proof;
    }

    function search(Sha256 node_id) view public returns (bool exist, NodeInfo node){
        node = nodes[node_id.digest()];
        if(node.exist().flag()==true) return (true,node);
        else return (false,node);
    }
}
