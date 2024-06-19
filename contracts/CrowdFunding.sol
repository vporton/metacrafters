// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFunding {
    IERC20 immutable token;
    
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
    function fund(uint64 _campaignId, uint256 _amount) duringCampaign(_campaignId) public {
        funded[_campaignId][msg.sender] += _amount;
        emit Fund(_campaignId, _amount);
        token.transferFrom(msg.sender, address(this), _amount); // I don't check return value, because our token reverts
    }

    event Withdraw(uint64 _campaignId, uint256 _amount);

    function withdraw(uint64 _campaignId, uint256 _amount) public afterCampaign(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        if (campaign.status == CampaignStatus.NONE) {
            // the first withdrawal follow
            require(campaign.locked < campaign.goal, "cannot withdraw: campaign fully funded");
            campaign.status = CampaignStatus.DIDNT_MEET_GOAL;
        } else {
            require(campaign.status == CampaignStatus.DIDNT_MEET_GOAL, "cannot withdraw: campaign fully funded");
        }
        campaign.locked -= _amount;
        emit Withdraw(_campaignId, _amount);
        token.transfer(msg.sender, _amount); // I don't check return value, because our token reverts
    }

    event Take(uint64 _campaignId, address _to, uint256 _amount);

    function takeFunds(uint64 _campaignId, address _to, uint256 _amount) public afterCampaign(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.recipient, "you aren't the campaign recipient");
        if (campaign.status == CampaignStatus.NONE) {
            // the first take funds follow
            require(campaign.locked >= campaign.goal, "campaign isn't fully funded");
            campaign.status = CampaignStatus.MET_GOAL;
        } else {
            require(campaign.status == CampaignStatus.MET_GOAL, "campaign isn't fully funded");
        }
        campaign.locked -= _amount;
        emit Take(_campaignId, _to, _amount);
        token.transfer(_to, campaign.locked); // I don't check return value, because our token reverts
    }

    modifier duringCampaign(uint64 _campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.timeline, "not during campaign");
        _;
    }

    modifier afterCampaign(uint64 _campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.timeline, "campaign didn't end yet");
        _;
    }
}
