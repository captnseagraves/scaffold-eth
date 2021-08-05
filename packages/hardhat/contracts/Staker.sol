pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public totalDeposited;
  uint256 public deadline;
  bool public executed = false;

  modifier deadlineCheck {
    require(now >= deadline, "Not past staking deadline yet");
    _;
  }

  modifier notCompleted {
      require(exampleExternalContract.completed() == false, "Staking threshold already filled and executed");
    _;
  }

  event Stake(address _staker, uint256 _amount); 

  constructor(address exampleExternalContractAddress) public {
    deadline = block.timestamp + 30 seconds;
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  function stake() public payable notCompleted {
    balances[msg.sender] += msg.value;
    totalDeposited += msg.value;

    // if (totalDeposited >= threshold) {
    //   exampleExternalContract.complete{value: address(this).balance}();
    //   totalDeposited = 0;
    // }

    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  function execute() public deadlineCheck notCompleted {
    require(address(this).balance >= threshold, "Cannot execute, threshold has not been met yet");

    exampleExternalContract.complete{value: address(this).balance}();
    totalDeposited = 0;
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  function withdraw() public deadlineCheck notCompleted {
    require(balances[msg.sender] > 0, "User has not staked any ETH");
    require(address(this).balance <= threshold, "Cannot withdraw stake, threshold has been met");

    uint256 amount = balances[msg.sender];

    totalDeposited -= amount;
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns (uint256 _amountTimeLeft) {
    uint256 amountTimeLeft = deadline - now; 

    if (now >= deadline) {
      return 0;
    } else {
      return amountTimeLeft;
    }
  }
}
