// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "../src/KassUtils.sol";
import "../src/factory/KassERC1155.sol";
import "./KassTestBase.sol";

// solhint-disable contract-name-camelcase

contract TestSetup_1155_KassClaimOwnership is KassTestBase {
    KassERC1155 public _l1TokenInstance;

    function setUp() public override {
        super.setUp();

        // request and create L1 instance
        requestL1InstanceCreation(L2_TOKEN_ADDRESS, L2_TOKEN_URI, TokenStandard.ERC1155);
        _l1TokenInstance = KassERC1155(_kass.createL1Instance1155(L2_TOKEN_ADDRESS, L2_TOKEN_URI));
    }
}

contract Test_1155_KassClaimOwnership is TestSetup_1155_KassClaimOwnership {

    function test_1155_claimOwnershipOnL1() public {
        address l1Owner = address(this);

        // claim ownership on L2
        claimOwnershipOnL1(L2_TOKEN_ADDRESS, l1Owner);
        expectL1OwnershipClaim(L2_TOKEN_ADDRESS, l1Owner);
        _kass.claimL1Ownership(L2_TOKEN_ADDRESS);

        assertEq(_l1TokenInstance.owner(), l1Owner);
    }
}
