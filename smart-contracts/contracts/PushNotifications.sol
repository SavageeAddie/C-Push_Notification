// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

/**
 * @title PushNotifications
 * @dev This contract manages push notifications for different channels, allowing users to subscribe, unsubscribe, and receive notifications.
 */
contract PushNotifications {
    /// @notice Emitted when a notification is sent to a specific recipient in a channel.
    event NotifyOneInChannel(
        address indexed recipient,
        uint256 indexed channel,
        string title,
        string action,
        string body,
        string imageHash,
        bool privateNotification
    );

    /// @notice Emitted when a notification is sent to all subscribers in a channel.
    event NotifyAllInChannel(
        uint256 indexed channel,
        string title,
        string action,
        string body,
        string imageHash
    );

    /// @dev Struct representing a channel's information.
    struct Channel {
        string name;
        string description;
        string iconHash;
        string badgeHash;
        address admin;
        address[] subscribers;
    }

    /// @dev Mapping of channel index to a mapping of addresses with push access permissions.
    mapping(uint256 => mapping(address => bool)) public pushAccess;

    /// @dev Array of channels containing information on various channels.
    Channel[] public channels;

    /// @dev Mapping of user address to a mapping of channel indices to subscription status.
    mapping(address => mapping(uint256 => bool)) public subscriptions;

    /// @dev Mapping of user address to their public keys used for private notifications.
    mapping(address => string) public publicKeys;

    /**
     * @notice Allows a user to subscribe to a channel.
     * @param _channel The index of the channel to subscribe to.
     * @return True if subscription is successful.
     */
    function subscribe(uint256 _channel) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        require(!subscriptions[msg.sender][_channel], "Already subscribed");
        subscriptions[msg.sender][_channel] = true;
        channels[_channel].subscribers.push(msg.sender);
        return true;
    }

    /**
     * @notice Allows a user to unsubscribe from a channel.
     * @param _channel The index of the channel to unsubscribe from.
     * @return True if unsubscription is successful.
     */
    function unsubscribe(uint256 _channel) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        require(subscriptions[msg.sender][_channel], "Not subscribed");
        subscriptions[msg.sender][_channel] = false;

        Channel storage channel = channels[_channel];
        uint256 indexToBeDeleted;
        for (uint256 i = 0; i < channel.subscribers.length; i++) {
            if (channel.subscribers[i] == msg.sender) {
                indexToBeDeleted = i;
                break;
            }
        }
        channel.subscribers[indexToBeDeleted] = channel.subscribers[channel.subscribers.length - 1];
        channel.subscribers.pop();
        return true;
    }

    /**
     * @notice Creates a new channel.
     * @param _name The name of the channel.
     * @param _description The description of the channel.
     * @param _iconHash The hash of the channel's icon.
     * @param _badgeHash The hash of the channel's badge.
     * @return The index of the newly created channel.
     */
    function createChannel(
        string memory _name,
        string memory _description,
        string memory _iconHash,
        string memory _badgeHash
    ) public returns (uint256) {
        Channel memory channel = Channel({
            name: _name,
            description: _description,
            iconHash: _iconHash,
            badgeHash: _badgeHash,
            admin: msg.sender,
            subscribers: new address  // Correctly initializing the subscribers array
        });
        channels.push(channel);
        return channels.length - 1;
    }

    /**
     * @notice Edits an existing channel's information.
     * @param _channel The index of the channel to edit.
     * @param _name The new name of the channel.
     * @param _description The new description of the channel.
     * @param _iconHash The new icon hash of the channel.
     * @param _badgeHash The new badge hash of the channel.
     * @return True if the channel is successfully edited.
     */
    function editChannel(
        uint256 _channel,
        string memory _name,
        string memory _description,
        string memory _iconHash,
        string memory _badgeHash
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        require(msg.sender == channels[_channel].admin, "Only the admin can edit the channel");
        Channel storage channel = channels[_channel];
        channel.name = _name;
        channel.description = _description;
        channel.iconHash = _iconHash;
        channel.badgeHash = _badgeHash;
        return true;
    }

    /**
     * @notice Sets the public key for a user.
     * @param _publicKey The public key to set.
     * @return True if the public key is successfully set.
     */
    function setPublicKey(string memory _publicKey) public returns (bool) {
        publicKeys[msg.sender] = _publicKey;
        return true;
    }

    /**
     * @notice Sets the push access for an address in a specific channel.
     * @param _channel The index of the channel.
     * @param _address The address to grant or revoke push access.
     * @param _access True to grant access, false to revoke.
     * @return True if the push access is successfully set.
     */
    function setPushAccess(uint256 _channel, address _address, bool _access) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        require(msg.sender == channels[_channel].admin, "Only the admin can set push access");
        pushAccess[_channel][_address] = _access;
        return true;
    }

    /**
     * @notice Sends a notification to a specific recipient in a channel.
     * @dev Fields like title, action, body, and imageHash should be encrypted by the sender if the notification is private.
     * @param _recipient The address of the recipient.
     * @param _channel The index of the channel.
     * @param _title The title of the notification.
     * @param _action The action associated with the notification.
     * @param _body The body of the notification.
     * @param _imageHash The hash of the image associated with the notification.
     * @param _privateNotification True if the notification is private.
     * @return True if the notification is successfully sent.
     */
    function notifyOneInChannel(
        address _recipient,
        uint256 _channel,
        string memory _title,
        string memory _action,
        string memory _body,
        string memory _imageHash,
        bool _privateNotification
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        Channel memory channel = channels[_channel];
        if (_privateNotification) {
            require(msg.sender == channel.admin, "Only the admin can send private notifications");
        } else {
            require(
                msg.sender == channel.admin || pushAccess[_channel][msg.sender],
                "Only the admin or authorized addresses can send notifications"
            );
        }
        require(subscriptions[_recipient][_channel], "Recipient is not subscribed to the channel");
        emit NotifyOneInChannel(_recipient, _channel, _title, _action, _body, _imageHash, _privateNotification);
        return true;
    }

    /**
     * @notice Sends a notification to all subscribers in a channel.
     * @param _channel The index of the channel.
     * @param _title The title of the notification.
     * @param _action The action associated with the notification.
     * @param _body The body of the notification.
     * @param _imageHash The hash of the image associated with the notification.
     * @return True if the notification is successfully sent.
     */
    function notifyAllInChannel(
        uint256 _channel,
        string memory _title,
        string memory _action,
        string memory _body,
        string memory _imageHash
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist");
        Channel memory channel = channels[_channel];
        require(
            msg.sender == channel.admin || pushAccess[_channel][msg.sender],
            "Only the admin or authorized addresses can send notifications"
        );
        emit NotifyAllInChannel(_channel, _title, _action, _body, _imageHash);
        return true;
    }

    /**
     * @notice Gets the number of subscribers in a channel.
     * @param _channel The index of the channel.
     * @return The number of subscribers in the channel.
     */
    function subscribersCountInChannel(uint256 _channel) public view returns (uint256) {
        require(_channel < channels.length, "Channel does not exist");
        return channels[_channel].subscribers.length;
    }

    /**
     * @notice Gets the list of subscribers in a channel.
     * @param _channel The index of the channel.
     * @return An array of addresses subscribed to the channel.
     */
    function subscribersInChannel(uint256 _channel) public view returns (address[] memory) {
        require(_channel < channels.length, "Channel does not exist");
        return channels[_channel].subscribers;
    }

    /**
     * @notice Gets the details of a specific channel.
     * @param _channel The index of the channel.
     * @return The details of the specified channel.
     */
    function getChannelDetails(uint256 _channel) public view returns (Channel memory) {
        require(_channel < channels.length, "Channel does not exist");
        return channels[_channel];
    }

    /**
     * @notice Gets all the channels.
     * @return An array of all channels.
     */
    function allChannels() public view returns (Channel[] memory) {
        return channels;
    }
}
