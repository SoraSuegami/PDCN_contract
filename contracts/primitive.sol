pragma solidity >=0.5.1;

contract Pubkey {
    uint8[64] public pubkey;

    constructor(uint8[64] memory _pubkey) public {
        require(_pubkey.length == 64);
        pubkey = _pubkey;
    }

    function to_address() view public returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(pubkey)))));
    }
}

contract Sha256 {
    bytes32 public digest;

    constructor(bytes32 _hash) public {
        digest = _hash;
    }

    function generate(bytes memory _input) public returns (Sha256){
        digest = sha256(_input);
        return this;
    }
}

contract Signature {
    bytes public signature;

    constructor(bytes memory _signature) public {
        require(_signature.length == 65,"invalid length of the given signature");
        signature = _signature;
    }

    function verify(Sha256 _hash, address _signer) public view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes memory sig = signature;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha256(abi.encode(prefix, _hash.digest));

        require(v == 27 || v == 28, "invalid signature version");
        address recovered_address = ecrecover(prefixedHash, v, r, s);
        require(recovered_address != address(0x0), "recovered address is zero");

        return _signer == recovered_address;
    }
}


contract Existence {
    bool public flag;

    constructor() public {
        flag = false;
    }

    function add() public {
        flag = true;
    }

    function del() public {
        flag = false;
    }
}

