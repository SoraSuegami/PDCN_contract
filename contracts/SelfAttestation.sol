pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature,Existence} from "./primitive.sol";
import {NodeInfo} from "./NodeInfo.sol";

contract SelfAttestation {
    Sha256 node_id;
    Sha256 request_id;
    Sha256 result_digest;
    Signature witness;
    Existence public exist;

    constructor(Sha256 _node_id, Sha256 _request_id, Sha256 _result_digest, Signature _witness) public {
        node_id = _node_id;
        request_id = _request_id;
        result_digest = _result_digest;
        witness = _witness;
    }

    function digest() public returns (Sha256) {
        return new Sha256(bytes32(0)).generate(abi.encode(node_id.digest,request_id.digest,result_digest.digest));
    }

    function verify(NodeInfo _node_info) public returns (bool) {
        Sha256 _hash = digest();
        return _node_info.verify_signature(_hash,witness);
    }
}
