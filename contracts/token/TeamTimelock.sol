// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../lib/SafeMath.sol';

contract TeamTimeLock {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant  public PERIOD = 30 days;

    address public beneficiary;
    IERC20 public token;
    uint256 public fixedQuantity;
    uint256 public startTime;
    uint256 public cycleTimes;
    string public introduce;

    uint256 public cycle;           // cycle already received
    uint256 public hasReward;       // rewards already withdrawn

    event WithDraw(address indexed operator, address indexed to, uint256 amount);

    constructor(
        address _beneficiary,       // reward to address
        address _token,             // ERC20 token for reward
        uint256 _fixedQuantity,     // each month reward are fixed
        uint256 _startTime,         // time start compute
        uint256 _delay,             // delay from _startTime to release reward
        uint256 _cycleTimes,        // cycles for finish reward
        string memory _introduce    // introduction for contract usage
    ) {
        require(_beneficiary != address(0) && _token != address(0), "TimeLock: zero address");
        require(_fixedQuantity > 0, "TimeLock: fixedQuantity is zero");
        require(_cycleTimes > 0, "TimeLock: cycleTimes is zero");
        beneficiary = _beneficiary;
        token = IERC20(_token);
        fixedQuantity = _fixedQuantity;
        startTime = _startTime.add(_delay);
        cycleTimes = _cycleTimes;
        introduce = _introduce;
    }


    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getReward() public view returns (uint256) {
        // Has ended or not started
        if (cycle >= cycleTimes || block.timestamp <= startTime) {
            return 0;
        }
        uint256 pCycle = (block.timestamp.sub(startTime)).div(PERIOD);
        if (pCycle >= cycleTimes) {
            return token.balanceOf(address(this));
        }
        return pCycle.sub(cycle).mul(fixedQuantity);
    }

    function withDraw() external {
        uint256 reward = getReward();
        require(reward > 0, "TimeLock: no reward");
        uint256 pCycle = (block.timestamp.sub(startTime)).div(PERIOD);
        cycle = pCycle >= cycleTimes ? cycleTimes : pCycle;
        hasReward = hasReward.add(reward);
        token.safeTransfer(beneficiary, reward);
        emit WithDraw(msg.sender, beneficiary, reward);
    }

    // Update beneficiary address by the previous beneficiary.
    function setBeneficiary(address _newBeneficiary) public {
        require(msg.sender == beneficiary, "Not beneficiary");
        require(_newBeneficiary != address(0), "TimeLock: zero address");
        beneficiary = _newBeneficiary;
    }
}