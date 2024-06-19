// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFunding {
    IERC20 token;
    
    uint64 nextCampaignId = 0;

    enum CampaignStatus { NONE, MET_GOAL, DIDNT_MEET_GOAL }

    struct Campaign {
        address recipient;
        uint256 goal;
        uint256 locked;
        uint64 timeline;
        CampaignStatus status;
    }

    mapping (uint64 => Campaign) campaigns;

    // campaign => (user => funds)
    mapping (uint64 => mapping (address => uint256)) funded;

    // Enhancement proposal beyond requested specification: Make token per-campaign.
    constructor(IERC20 _token) {
        token = _token;
    }

    event CreateCampaign(address _recipient, uint256 _goal, uint64 _timeline);

    function createCampaign(address _recipient, uint256 _goal, uint64 _timeline) public returns (uint64 campaignId) {
        Campaign memory campaign = Campaign({
            recipient: _recipient,
            goal: _goal,
            locked: 0,
            timeline: _timeline,
            status: CampaignStatus.NONE
        });
        campaignId = nextCampaignId++;
        campaigns[campaignId] = campaign;
        emit CreateCampaign(_recipient, _goal, _timeline);
    }

    event Fund(uint64 _campaignId, uint256 _amount);

    // Requires prior token allowance.
    function fund(uint64 _campaignId, uint256 _amount) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.timeline);
        funded[_campaignId][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Fund(_campaignId, _amount);
    }

    event Withdraw(uint64 _campaignId, uint256 _amount);

    function withdraw(uint64 _campaignId, uint256 _amount) public {
        Campaign storage campaign = campaigns[_campaignId];
        if (campaign.status == CampaignStatus.NONE) {
            // the first withdrawal follow
            require(campaign.locked < campaign.goal && block.timestamp >= campaign.timeline);
            campaign.status = CampaignStatus.DIDNT_MEET_GOAL;
        } else {
            require(campaign.status == CampaignStatus.DIDNT_MEET_GOAL);
        }
        campaign.locked -= _amount;
        token.transfer(msg.sender, _amount);
        emit Withdraw(_campaignId, _amount);
    }

    event Take(uint64 _campaignId, address _to, uint256 _amount);

    function takeFunds(uint64 _campaignId, address _to, uint256 _amount) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.timeline && msg.sender == campaign.recipient);
        if (campaign.status == CampaignStatus.NONE) {
            // the first take funds follow
            require(campaign.locked >= campaign.goal);
            campaign.status = CampaignStatus.MET_GOAL;
        } else {
            require(campaign.status == CampaignStatus.MET_GOAL);
        }
        campaign.locked -= _amount;
        token.transfer(_to, campaign.locked);
        emit Take(_campaignId, _to, _amount);
    }
}
