# PWN Bundler 

The contract enables to bundle ERC20, ERC721, ERC1155 into a single ERC1155 token. The contract is completely permissionless. 
The only constrain is the array size - currently the contract can't hold more than 10 distinct tokens. 

The owner of the bundleNFT has rights to:
 - add additional tokens until the bundle size limit is reached
 - remove tokens from the bundle opening up a slot
 - unwrap the entire bundle resulting in burning the bundle token and gaining ownership over the wrapped tokens


# Q&A: 
### Q: If I insert the fungible token which is already present in the bundle, will it add up to the current bundle slot? 
A:
No, each addition will appear on a unique slot in the bundle. You can however remove the fungible token from the bundle first and then re-add it with a new amount.

### Q: Is this real? Am I real?  
A:
Yes, it's real. And yea, unless you are a crawler or a programmed bot parsing this text, we can safely assume you are real indeed. In the case you are actually a program parsing this text, then I don't think there is a an objective consensus reached about that question yet. We'll see. 
