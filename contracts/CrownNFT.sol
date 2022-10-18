// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './Hook.sol';




contract CrownNFT is ERC721,Ownable{
    constructor(address _ERC20)ERC721('crown', 'crn'){
        poap = new POAP();
        poapAddress = address(poap);
        TransactionAndHookContract = new TransactionsAndHook(_ERC20, address(this), poapAddress, msg.sender);
        transactionAndHookAddress = payable (address(TransactionAndHookContract));
        poap.updateHook(transactionAndHookAddress);
        _mint(msg.sender, 0);
    }
    event Log(string message);
    
    event Log(address payable ad);
    event Log(uint ui);

    POAP poap;
    address public poapAddress;

    address payable public  transactionAndHookAddress;
    TransactionsAndHook TransactionAndHookContract;
    string public baseUri = "https://gateway.pinata.cloud/ipfs/QmUQLowzXxNqtGqCxq2YgAxo9R31ixS4AuGFVQMU96BX3V/";
    
     function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    

    function transferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public pure override{
        revert('transfers must be superPurchases');
    }


    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public pure override{
        revert('transfers must be superPurchases');
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/, bytes memory /*_data*/) public pure  override{
        revert('transfers must be superPurchases');
    }
  


    function superPurchase() public payable {
        address payable currentOwner = payable(ownerOf(0));
        uint minimumSalesPrice = TransactionAndHookContract.getLastEthRecieved() * 1015 / 1000;
        require(msg.value >= minimumSalesPrice, "Not enough ETH - purchase price is 1.5% higher than last purchase price");
        payable(msg.sender).transfer(msg.value - minimumSalesPrice);
        TransactionAndHookContract.superBuy{value: minimumSalesPrice}(msg.sender);
        _transfer(currentOwner,msg.sender,0);
        
    }

}

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