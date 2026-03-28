// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VetoVault is Ownable {
    struct Proposal {
        uint256 eta;
        bool executed;
        bool vetoed;
        uint256 vetoPower;
        address target;
        bytes data;
        uint256 value;
    }

    IERC20 public immutable governanceToken;
    uint256 public constant CHALLENGE_WINDOW = 2 days;
    uint256 public constant MIN_STAKE_DURATION = 180 days;
    uint256 public vetoThreshold;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userStakeTime;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event VetoCast(uint256 indexed proposalId, address indexed voter, uint256 power);
    event Executed(uint256 indexed proposalId);
    event Vetoed(uint256 indexed proposalId);

    constructor(address _token, uint256 _threshold) Ownable(msg.sender) {
        governanceToken = IERC20(_token);
        vetoThreshold = _threshold;
    }

    function registerStake() external {
        if (userStakeTime[msg.sender] == 0) {
            userStakeTime[msg.sender] = block.timestamp;
        }
    }

    function queueProposal(uint256 id, address target, uint256 value, bytes calldata data) external onlyOwner {
        require(proposals[id].eta == 0, "Already queued");
        proposals[id] = Proposal({
            eta: block.timestamp + CHALLENGE_WINDOW,
            executed: false,
            vetoed: false,
            vetoPower: 0,
            target: target,
            data: data,
            value: value
        });
        emit ProposalQueued(id, proposals[id].eta);
    }

    function castVeto(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.eta > 0, "Not queued");
        require(block.timestamp <= p.eta, "Window closed");
        require(!p.vetoed, "Already vetoed");
        require(!hasVoted[id][msg.sender], "Already voted");
        require(userStakeTime[msg.sender] != 0 && (block.timestamp - userStakeTime[msg.sender]) >= MIN_STAKE_DURATION, "Stake too fresh");

        uint256 power = governanceToken.balanceOf(msg.sender);
        require(power > 0, "No power");

        hasVoted[id][msg.sender] = true;
        p.vetoPower += power;

        emit VetoCast(id, msg.sender, power);

        if (p.vetoPower >= vetoThreshold) {
            p.vetoed = true;
            emit Vetoed(id);
        }
    }

    function execute(uint256 id) external payable {
        Proposal storage p = proposals[id];
        require(p.eta > 0, "Not queued");
        require(block.timestamp > p.eta, "Window open");
        require(!p.executed, "Already executed");
        require(!p.vetoed, "Proposal vetoed");

        p.executed = true;
        (bool success, ) = p.target.call{value: p.value}(p.data);
        require(success, "Execution failed");

        emit Executed(id);
    }

    function updateThreshold(uint256 newThreshold) external onlyOwner {
        vetoThreshold = newThreshold;
    }

    receive() external payable {}
}