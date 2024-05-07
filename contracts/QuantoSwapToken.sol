pragma solidity 0.6.12;

import "./lib/ERC20MaxSupplyPreMine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract QuantoSwapToken is ERC20MaxSupply('QuantoSwap Token', 'QNS'), Ownable {

    uint256 private constant _preMined = 1000000000000000000000000;

    constructor (address _preMineReceiver) public {
        QuantoSwapToken.mint(_preMineReceiver, _preMined);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
}