pragma solidity >=0.5.1;

import {Sha256,Pubkey,Signature} from "./primitive.sol";
import {RequestInfo} from "./RequestInfo.sol";
import {SelfAttestation} from "./SelfAttestation.sol";
import {NodeInfo} from "./NodeInfo.sol";
import {NodeRegister} from "./NodeRegister.sol";

contract MatchingMarket {
    mapping(bytes32 => RequestInfo) public requests;
    mapping(bytes32 => uint256) public deposits;
    mapping(bytes32 => SelfAttestation) public proofs;
    mapping(address => uint256) public nonces;

    NodeRegister node_register = new NodeRegister();

    bytes constant cancel_prefix = "43616e63656c2072657175657374206f662070726f70616761746976652054454520636f6d7075746174696f6e";

    function register(address _client,Sha256 _node_id,Sha256 _circuit_digest, Sha256 _input_digest, uint256 _expired, Signature _witness) public payable {
        uint256 _nonce = nonces[_client];
        require(_nonce>=0&&_nonce<2**256-1,"the nonce is max number");
        require(block.number<_expired,"invalid expire time");
        RequestInfo request = new RequestInfo(_client,msg.value,_node_id,_circuit_digest,_input_digest,_expired,_nonce,_witness);
        require(request.verify(),"invalid request");
        bytes32 key = request.digest().digest();
        (bool exist,) = search(key);
        require(exist==false,"the request already exists");
        request.exist().add();
        requests[key] = request;
        nonces[_client] += 1;
        deposits[key] = msg.value;
    }

    function complete(Sha256 _node_id, Sha256 _request_id, Sha256 _result_digest, Signature _witness) public {
        bytes32 key = _request_id.digest();
        (bool req_exist, RequestInfo request) = search(key);
        require(req_exist==true&&key==request.digest().digest(),"the request does not exist");
        require(block.number<request.expired(),"the request is expired");
        require(proofs[key].exist().flag()==false,"the proof already exists");
        (bool node_exist, NodeInfo node) = node_register.search(_node_id);
        require(node_exist==true,"the node does not exist");
        SelfAttestation proof = new SelfAttestation(_node_id,_request_id,_result_digest,_witness);
        require(proof.verify(node),"invalid proof");
        address payable node_address = address(uint160(node.pubkey().to_address()));
        proof.exist().add();
        proofs[key] = proof;
        erase(key,node_address);
    }

    function cancel(bytes32 _key,Signature _witness) public {
        (bool exist, RequestInfo request) = search(_key);
        require(exist==true&&_key==request.digest().digest(),"the request does not exist");
        address payable client = address(uint160(request.client()));
        Sha256 _hash = new Sha256(bytes32(0)).generate(abi.encode(cancel_prefix,_key));
        require(_witness.verify(_hash,client),"invalid signature");
        erase(_key,client);
    }

    function search(bytes32 _key) view public returns(bool exist,RequestInfo request) {
        request = requests[_key];
        if(request.exist().flag()==true) return (true,request);
        else return (false,request);
    }

    function erase(bytes32 _key,address payable receiver) private {
        uint256 amount = deposits[_key];
        deposits[_key] = 0;
        receiver.transfer(amount);
    }
}
