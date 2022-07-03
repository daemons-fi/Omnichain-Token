// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Omnitoken is ERC20, Ownable, ILayerZeroReceiver {
    uint256 public constant MAX_SUPPLY = 100 * 1e18; // 100
    address private lzEndpoint;

    mapping(uint16 => address) public omnitokenInOtherChains;

    constructor(address _lzEndpoint) ERC20("Omnitoken", "OMNI") {
        lzEndpoint = _lzEndpoint;
        _mint(_msgSender(), MAX_SUPPLY);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOmnitokenAddressOnOtherChain(
        uint16 _dstChainId,
        address _address
    ) external onlyOwner {
        omnitokenInOtherChains[_dstChainId] = _address;
    }

    /* ========== LAYER ZERO EXTERNAL FUNCTIONS ========== */

    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    function lzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == lzEndpoint);
        (address toAddress, uint256 amount) = abi.decode(
            _payload,
            (address, uint256)
        );
        _mint(toAddress, amount);
    }

    function crossChainTransfer(
        address _to,
        uint256 _amount,
        uint16 _dstChainId
    ) external payable {
        require(
            balanceOf(_msgSender()) >= _amount,
            "ERC20: amount exceeds balance"
        );

        address omnitokenAddress = omnitokenInOtherChains[_dstChainId];
        require(omnitokenAddress != address(0), "Chain not supported");
        ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(lzEndpoint);
        bytes memory payload = abi.encode(_to, _amount);

        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            _to,
            payload,
            false,
            bytes("")
        );
        require(
            msg.value >= messageFee,
            "Not enough to cover fee"
        );

        endpoint.send{value: msg.value}(
            _dstChainId,
            abi.encodePacked(omnitokenAddress),
            payload,
            payable(msg.sender),
            _msgSender(),
            bytes("")
        );

        _burn(_msgSender(), _amount);
    }

    /* ========== LAYER ZERO VIEWS ========== */

    function isChainSupported(uint16 _dstChainId) external view returns (bool) {
        return omnitokenInOtherChains[_dstChainId] != address(0);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
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
