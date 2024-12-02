
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwappingContract is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct SwapOffer {
        address creator;
        address tokenToGive;
        uint256 amountToGive;
        address tokenToReceive;
        uint256 amountToReceive;
        bool isActive;
    }

    mapping(uint256 => SwapOffer) public swapOffers;
    uint256 public nextSwapOfferId;

    event SwapOfferCreated(uint256 indexed offerId, address indexed creator, address tokenToGive, uint256 amountToGive, address tokenToReceive, uint256 amountToReceive);
    event SwapOfferAccepted(uint256 indexed offerId, address indexed acceptor);
    event SwapOfferCancelled(uint256 indexed offerId);

    function createSwapOffer(
        address _tokenToGive,
        uint256 _amountToGive,
        address _tokenToReceive,
        uint256 _amountToReceive
    ) external nonReentrant {
        require(_tokenToGive != address(0) && _tokenToReceive != address(0), "Invalid token addresses");
        require(_amountToGive > 0 && _amountToReceive > 0, "Invalid amounts");

        uint256 offerId = nextSwapOfferId++;

        swapOffers[offerId] = SwapOffer({
            creator: msg.sender,
            tokenToGive: _tokenToGive,
            amountToGive: _amountToGive,
            tokenToReceive: _tokenToReceive,
            amountToReceive: _amountToReceive,
            isActive: true
        });

        IERC20(_tokenToGive).safeTransferFrom(msg.sender, address(this), _amountToGive);

        emit SwapOfferCreated(offerId, msg.sender, _tokenToGive, _amountToGive, _tokenToReceive, _amountToReceive);
    }

    function acceptSwapOffer(uint256 _offerId) external nonReentrant {
        SwapOffer storage offer = swapOffers[_offerId];
        require(offer.isActive, "Swap offer is not active");

        offer.isActive = false;

        IERC20(offer.tokenToReceive).safeTransferFrom(msg.sender, offer.creator, offer.amountToReceive);
        IERC20(offer.tokenToGive).safeTransfer(msg.sender, offer.amountToGive);

        emit SwapOfferAccepted(_offerId, msg.sender);
    }

    function cancelSwapOffer(uint256 _offerId) external nonReentrant {
        SwapOffer storage offer = swapOffers[_offerId];
        require(offer.isActive, "Swap offer is not active");
        require(offer.creator == msg.sender, "Only the creator can cancel the offer");

        offer.isActive = false;

        IERC20(offer.tokenToGive).safeTransfer(offer.creator, offer.amountToGive);

        emit SwapOfferCancelled(_offerId);
    }

    function getSwapOffer(uint256 _offerId) external view returns (SwapOffer memory) {
        return swapOffers[_offerId];
    }
}
