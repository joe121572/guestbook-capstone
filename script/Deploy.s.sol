// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Guestbook} from "../src/Guestbook.sol";

contract DeployGuestbook is Script {
    function run() external returns (Guestbook) {
        vm.startBroadcast();
        Guestbook guestbook = new Guestbook();
        vm.stopBroadcast();
        return guestbook;
    }
}