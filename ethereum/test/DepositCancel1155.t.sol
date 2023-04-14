// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../src/KassUtils.sol";
import "../src/factory/KassERC1155.sol";
import "./KassTestBase.sol";

// solhint-disable contract-name-camelcase

contract TestSetup_1155_DepositCancel is KassTestBase, ERC1155Holder {
    KassERC1155 public _l1TokenWrapper;

    function setUp() public override {
        super.setUp();

        // request and create L1 instance
        requestL1WrapperCreation(L2_TOKEN_ADDRESS, L2_TOKEN_URI, TokenStandard.ERC1155);
        _l1TokenWrapper = KassERC1155(
            _kass.createL1Wrapper1155(L2_TOKEN_ADDRESS, L2_TOKEN_URI)
        );
    }

    function _1155_mintAndDepositBackOnL2(
        uint256 l2TokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 l2Recipient,
        uint256 nonce
    ) internal {
        address sender = address(this);

        uint256 balance = _l1TokenWrapper.balanceOf(sender, tokenId);

        // mint tokens
        vm.prank(address(_kass));
        _l1TokenWrapper.mint(sender, tokenId, amount);

        // deposit tokens on L2
        expectDepositOnL2(sender, l2TokenAddress, tokenId, amount, l2Recipient, nonce);
        _kass.deposit1155(l2TokenAddress, tokenId, amount, l2Recipient);

        // check if balance is correct
        assertEq(_l1TokenWrapper.balanceOf(sender, tokenId), balance);
    }

    function _1155_basicDepositCancelTest(
        uint256 l2TokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 l2Recipient,
        uint256 nonce
    ) internal {
        address sender = address(this);

        uint256 balance = _l1TokenWrapper.balanceOf(sender, tokenId);

        // deposit on L1 and send back to L2
        _1155_mintAndDepositBackOnL2(l2TokenAddress, tokenId, amount, l2Recipient, nonce);

        // deposit cancel request
        expectDepositCancelRequest(sender, l2TokenAddress, tokenId, amount, l2Recipient, nonce);
        _kass.requestDepositCancel1155(l2TokenAddress, tokenId, amount, l2Recipient, nonce);

        // check if balance still the same
        assertEq(_l1TokenWrapper.balanceOf(sender, tokenId), balance);

        // deposit cancel request
        expectDepositCancel(sender, l2TokenAddress, tokenId, amount, l2Recipient, nonce);
        _kass.cancelDeposit1155(l2TokenAddress, tokenId, amount, l2Recipient, nonce);

        // check if balance was updated
        assertEq(_l1TokenWrapper.balanceOf(sender, tokenId), balance + amount);
    }
}

contract Test_1155_DepositCancel is TestSetup_1155_DepositCancel {

    function test_1155_DepositCancel_1() public {
        uint256 l2Recipient = uint256(keccak256("rando 1")) % CAIRO_FIELD_PRIME;
        uint256 tokenId = uint256(keccak256("token 1"));
        uint256 amount = uint256(keccak256("huge amount"));
        uint256 nonce = uint256(keccak256("huge nonce"));

        _1155_basicDepositCancelTest(L2_TOKEN_ADDRESS, tokenId, amount, l2Recipient, nonce);
    }

    function test_1155_DepositCancel_2() public {
        uint256 l2Recipient = uint256(keccak256("rando 1")) % CAIRO_FIELD_PRIME;
        uint256 tokenId = uint256(keccak256("token 1"));
        uint256 amount = 0x100;
        uint256 nonce = 0x0;

        _1155_basicDepositCancelTest(L2_TOKEN_ADDRESS, tokenId, amount, l2Recipient, nonce);
    }

    function test_1155_CannotRequestDepositCancelForAnotherDepositor() public {
        address fakeSender = address(uint160(uint256(keccak256("rando 1"))));
        uint256 l2Recipient = uint256(keccak256("rando 1")) % CAIRO_FIELD_PRIME;
        uint256 tokenId = uint256(keccak256("token 1"));
        uint256 amount = 0x100;
        uint256 nonce = 0x0;

        _1155_mintAndDepositBackOnL2(L2_TOKEN_ADDRESS, tokenId, amount, l2Recipient, nonce);

        vm.startPrank(fakeSender);
        vm.expectRevert("Caller is not the depositor");
        _kass.requestDepositCancel1155(L2_TOKEN_ADDRESS, tokenId, amount, l2Recipient, nonce);
    }

    function test_1155_CannotRequestDepositCancelForUnknownDeposit() public {
        uint256 l2Recipient = uint256(keccak256("rando 1")) % CAIRO_FIELD_PRIME;
        uint256 tokenId = uint256(keccak256("token 1"));
        uint256 amount = 0x100;
        uint256 nonce = 0x0;

        vm.expectRevert("Deposit not found");
        _kass.cancelDeposit1155(L2_TOKEN_ADDRESS, tokenId, amount, l2Recipient, nonce);
    }
}
