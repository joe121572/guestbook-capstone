// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {Guestbook} from "../src/Guestbook.sol";

contract GuestbookTest is Test {
    Guestbook private guestbook;

    event MessagePosted(
        uint256 indexed entryId,
        address indexed author,
        string message,
        uint256 timestamp
    );

    function setUp() public {
        guestbook = new Guestbook();
    }

    function test_PostMessageStoresEntryAndEmitsEvent() public {
        address author = address(0xA11CE);
        string memory message = "Hello, guestbook!";
        uint256 timestamp = 123;
        vm.warp(timestamp);
        vm.prank(author);
        vm.expectEmit(true, true, false, true, address(guestbook));
        emit MessagePosted(0, author, message, timestamp);

        guestbook.postMessage(message);

        assertEq(guestbook.entryCount(), 1);
        (address storedAuthor, string memory storedMessage, uint256 storedTimestamp) =
            guestbook.getEntry(0);
        assertEq(storedAuthor, author);
        assertEq(storedMessage, message);
        assertEq(storedTimestamp, timestamp);
    }

    function test_PostMessageAcceptsMaximumByteLength() public {
        string memory message = string(new bytes(guestbook.MAX_MESSAGE_BYTES()));

        guestbook.postMessage(message);

        assertEq(guestbook.entryCount(), 1);
    }

    function test_PostMessageRejectsEmptyMessage() public {
        vm.expectRevert("Message cannot be empty");
        guestbook.postMessage("");
    }

    function test_PostMessageRejectsMessageOverMaximumByteLength() public {
        string memory message = string(new bytes(guestbook.MAX_MESSAGE_BYTES() + 1));

        vm.expectRevert("Message too long");
        guestbook.postMessage(message);
    }

    function test_GetEntryRejectsMissingEntry() public {
        vm.expectRevert("Entry does not exist");
        guestbook.getEntry(0);
    }

    function test_AuthorCanEditMessage() public {
        address author = address(0xA11CE);
        vm.prank(author);
        guestbook.postMessage("Original message");

        vm.prank(author);
        guestbook.editMessage(0, "Edited message");

        (address storedAuthor, string memory message,) = guestbook.getEntry(0);
        assertEq(storedAuthor, author);
        assertEq(message, "Edited message");
    }

    function test_OtherUsersCannotEditMessage() public {
        vm.prank(address(0xA11CE));
        guestbook.postMessage("Original message");

        vm.prank(address(0xB0B));
        vm.expectRevert("Only the author can edit");
        guestbook.editMessage(0, "Edited message");
    }

    function test_GetEntriesReturnsBoundedPage() public {
        guestbook.postMessage("First");
        guestbook.postMessage("Second");
        guestbook.postMessage("Third");

        Guestbook.Entry[] memory page = guestbook.getEntries(1, 2);

        assertEq(page.length, 2);
        assertEq(page[0].message, "Second");
        assertEq(page[1].message, "Third");
    }

    function test_GetEntriesByAuthorReturnsOnlyTheirIds() public {
        address firstAuthor = address(0xA11CE);
        address secondAuthor = address(0xB0B);
        vm.prank(firstAuthor);
        guestbook.postMessage("First");
        vm.prank(secondAuthor);
        guestbook.postMessage("Second");
        vm.prank(firstAuthor);
        guestbook.postMessage("Third");

        uint256[] memory ids = guestbook.getEntriesByAuthor(firstAuthor);

        assertEq(ids.length, 2);
        assertEq(ids[0], 0);
        assertEq(ids[1], 2);
    }

    function test_GetEntriesRejectsOversizedPage() public {
        uint256 oversizedLimit = guestbook.MAX_PAGE_SIZE() + 1;
        vm.expectRevert("Invalid page size");
        guestbook.getEntries(0, oversizedLimit);
    }
}