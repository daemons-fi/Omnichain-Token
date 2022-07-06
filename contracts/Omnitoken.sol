// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Omnitoken is ERC20, Ownable, ILayerZeroReceiver {
    uint256 public constant MAX_SUPPLY = 100 * 1e18; // 100

    // the LZ endpoint we will be sending messages to
    address private lzEndpoint;

    // a map containing the addresses of the OMNI token of various chains
    mapping(uint16 => address) public omnitokenInOtherChains;

    constructor(address _lzEndpoint) ERC20("Omnitoken", "OMNI") {
        lzEndpoint = _lzEndpoint;
        _mint(_msgSender(), MAX_SUPPLY);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /** Sets the address of the OMNI token in a different chain */
    function setOmnitokenAddressOnOtherChain(
        uint16 _dstChainId,
        address _address
    ) external onlyOwner {
        omnitokenInOtherChains[_dstChainId] = _address;
    }

    /* ========== LAYER ZERO EXTERNAL FUNCTIONS ========== */

    /** LayerZero endpoint will invoke this function to deliver the message on the destination */
    function lzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) external override {
        // let's make sure that only the LayerZero endpoint can call this method
        require(msg.sender == lzEndpoint);

        // decode destination address and amount, sent in the message payload
        (address toAddress, uint256 amount) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the amount of tokens at the destination address
        _mint(toAddress, amount);
    }

    /** Sends the specified amount of tokens to an address on a different chain */
    function crossChainTransfer(
        address _to,
        uint256 _amount,
        uint16 _dstChainId
    ) external payable {
        require(
            balanceOf(_msgSender()) >= _amount,
            "ERC20: amount exceeds balance"
        );

        // check if we have the address of the OMNI token for the specified chain
        address omnitokenAddress = omnitokenInOtherChains[_dstChainId];
        require(omnitokenAddress != address(0), "Chain not supported");

        ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(lzEndpoint);

        // encode payload
        bytes memory payload = abi.encode(_to, _amount);

        // estimate fees and check if user passed enough to complete the operation
        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            _to,
            payload,
            false,
            bytes("")
        );
        require(msg.value >= messageFee, "Not enough to cover fee");

        // send message to LayerZero relayer
        endpoint.send{value: msg.value}(
            _dstChainId,                         // the LZ id of the destination chain
            abi.encodePacked(omnitokenAddress),  // the OMNI token in the destination chain
            payload,                             // the message payload
            payable(_msgSender()),               // where to send the excess fee
            _msgSender(),                        // currently unused
            bytes("")                            // currently unused
        );

        _burn(_msgSender(), _amount);
    }

    /* ========== LAYER ZERO VIEWS ========== */

    /** Checks if the chain is supported by passing the LZ id of the destination chain */
    function isChainSupported(uint16 _dstChainId) external view returns (bool) {
        return omnitokenInOtherChains[_dstChainId] != address(0);
    }

   /** Estimates the fees for the message */
    function estimateFees(
        address _to,
        uint256 _amount,
        uint16 _dstChainId
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(_to, _amount);
        return
            ILayerZeroEndpoint(lzEndpoint).estimateFees(
                _dstChainId,
                _to,
                payload,
                false,
                bytes("")
            );
    }
}
