// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Guestbook {
    uint256 public constant MAX_MESSAGE_BYTES = 280;
    uint256 public constant MAX_PAGE_SIZE = 100;

    struct Entry {
        address author;
        string message;
        uint256 timestamp;
    }

    Entry[] private entries;
    mapping(address => uint256[]) private authorToEntryIds;

    event MessagePosted(
        uint256 indexed entryId,
        address indexed author,
        string message,
        uint256 timestamp
    );

    event MessageEdited(
        uint256 indexed entryId,
        address indexed author,
        string newMessage,
        uint256 timestamp
    );

    function postMessage(string calldata message) external {
        uint256 messageLength = bytes(message).length;

        require(messageLength > 0, "Message cannot be empty");
        require(messageLength <= MAX_MESSAGE_BYTES, "Message too long");

        uint256 entryId = entries.length;

        entries.push(Entry({
            author: msg.sender,
            message: message,
            timestamp: block.timestamp
        }));

        authorToEntryIds[msg.sender].push(entryId);

        emit MessagePosted(entryId, msg.sender, message, block.timestamp);
    }

    function editMessage(uint256 entryId, string memory newMessage) external {
        require(entryId < entries.length, "Entry does not exist");
        Entry storage entry = entries[entryId];
        require(entry.author == msg.sender, "Only the author can edit");
        
        uint256 messageLength = bytes(newMessage).length;
        require(messageLength > 0, "Message cannot be empty");
        require(messageLength <= MAX_MESSAGE_BYTES, "Message too long");

        entry.message = newMessage;
        entry.timestamp = block.timestamp;

        emit MessageEdited(entryId, msg.sender, newMessage, block.timestamp);
    }

    function entryCount() external view returns (uint256) {
        return entries.length;
    }

    function getEntry(uint256 entryId)
        external
        view
        returns (address author, string memory message, uint256 timestamp)
    {
        require(entryId < entries.length, "Entry does not exist");

        Entry storage entry = entries[entryId];
        return (entry.author, entry.message, entry.timestamp);
    }

    function getEntries(uint256 offset, uint256 limit) external view returns (Entry[] memory) {
        require(limit <= MAX_PAGE_SIZE, "Invalid page size");

        uint256 totalEntries = entries.length;
        if (offset >= totalEntries) {
            return new Entry[](0);
        }

        uint256 fetchLength = limit;
        if (offset + fetchLength > totalEntries) {
            fetchLength = totalEntries - offset;
        }

        Entry[] memory paginatedEntries = new Entry[](fetchLength);
        for (uint256 i = 0; i < fetchLength; i++) {
            paginatedEntries[i] = entries[offset + i];
        }

        return paginatedEntries;
    }

    function getEntriesByAuthor(address author) external view returns (uint256[] memory) {
        return authorToEntryIds[author];
    }
}