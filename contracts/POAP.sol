// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './Hook.sol';




contract POAP is ERC721,Ownable{
    constructor()ERC721('POAP', 'POAP'){        
    }

    address payable public  hookAddress;
    TransactionsAndHook Hook;
    uint nextTokenId;

    function updateHook(address payable _hookAddress) public onlyOwner{
        hookAddress=_hookAddress;
        Hook = TransactionsAndHook(hookAddress);
    }

     string public baseUri = "https://gateway.pinata.cloud/ipfs/QmUQLowzXxNqtGqCxq2YgAxo9R31ixS4AuGFVQMU96BX3V/";
    
     function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    

    function transferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public pure override{
        revert('Non transferable');
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public pure override{
        revert('Non transferable');
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/, bytes memory /*_data*/)public pure override{
        revert('Non transferable');
    }

    function mint(address to) external onlyHook{
        _mint(to, nextTokenId);
        nextTokenId++;
    }

    modifier onlyHook {
      require(msg.sender == hookAddress);
      _;
   }
}