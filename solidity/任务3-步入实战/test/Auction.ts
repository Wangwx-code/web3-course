import assert from "node:assert/strict";
import { describe, it, before, beforeEach, afterEach } from "node:test";
import { network } from "hardhat";
import { getCurrentNetworkName } from "../utils/network.js";
import "../ignition/modules/Auction.js";
import auctionModule from "../ignition/modules/Auction.js";

describe("NftAuction", async function () {
    const { viem, ethers, ignition } = await network.connect();
    const publicClient = await viem.getPublicClient();

    // Test accounts
    let deployer: any, seller: any, bidder1: any, bidder2: any, bidder3: any, admin: any;

    // Contract addresses
    let linkAddr: any, nftAddr: any, ethUsdFeed: any, linkUsdFeed: any;

    // Contract instances
    let linkContract: any, nftContract: any, auctionContract: any;

    // Constants
    const AUCTION_DURATION = 60; // 60 seconds for tests
    const FEE = 10n ** 16n; // 0.01 ETH
    const INITIAL_BID_VALUE = 100n; // $100 USD
    const LINK_DECIMALS = 18n;
    const USD_DECIMALS = 8n;
    const ETH_DECIMALS = 18n;

    // Helper functions
    const getContractBalance = async (address: any) => {
        return await publicClient.getBalance({ address });
    };

    const getLinkBalance = async (address: any) => {
        return await linkContract.read.balanceOf([address]);
    };

    const getNftOwner = async (tokenId: any) => {
        return await nftContract.read.ownerOf([tokenId]);
    };

    const increaseTime = async (seconds: any) => {
        await ethers.provider.send("evm_increaseTime", [Number(seconds)]);
        await ethers.provider.send("evm_mine");
    };

    const setNextBlockTimestamp = async (timestamp: any) => {
        await ethers.provider.send("evm_setNextBlockTimestamp", [Number(timestamp)]);
        await ethers.provider.send("evm_mine");
    };

    const getLatestBlockTimestamp = async (): Promise<number> => {
        const block = await publicClient.getBlock();
        return Number(block.timestamp);
    };

    before(async function () {
        const wallets = await viem.getWalletClients();
        [deployer, seller, bidder1, bidder2, bidder3, admin] = wallets;

        console.log("=== Test Configuration ===");
        console.log("Network:", getCurrentNetworkName());
        console.log("Seller:", seller.account.address);
        console.log("Bidder1:", bidder1.account.address);
        console.log("Bidder2:", bidder2.account.address);
        console.log("Admin:", admin.account.address);
    });

    beforeEach(async function () {
        // Deploy mock contracts for each test
        linkContract = await viem.deployContract("Link");
        linkAddr = linkContract.address;

        nftContract = await viem.deployContract("XingXingNft");
        nftAddr = nftContract.address;

        // Deploy mock price feeds
        const mockEthFeed = await viem.deployContract("MockAggregatorV3", [
            Number(USD_DECIMALS),
            2000n * 10n ** USD_DECIMALS // $2000 per ETH
        ]);

        const mockLinkFeed = await viem.deployContract("MockAggregatorV3", [
            Number(USD_DECIMALS),
            15n * 10n ** USD_DECIMALS // $15 per LINK
        ]);

        ethUsdFeed = mockEthFeed.address;
        linkUsdFeed = mockLinkFeed.address;

        const { auction } = await ignition.deploy(auctionModule, {
            parameters: {
                proxyModule: {
                    fee: FEE,
                    linkAddr,
                    ethUsdFeed,
                    linkUsdFeed
                }
            }
        });
        auctionContract = auction;

        // Setup initial balances
        await linkContract.write.mint([1000n * 10n ** LINK_DECIMALS]);
        await nftContract.write.mint(); // Token 1
        await nftContract.write.mint(); // Token 2
        await nftContract.write.mint(); // Token 3

        // Transfer NFTs to seller
        await nftContract.write.transferFrom([
            deployer.account.address, // from
            seller.account.address,   // to
            1n                        // tokenId
        ]);

        // Distribute LINK tokens to bidders
        const linkAmount = 200n * 10n ** LINK_DECIMALS;
        await linkContract.write.transfer([bidder1.account.address, linkAmount]);
        await linkContract.write.transfer([bidder2.account.address, linkAmount]);
        await linkContract.write.transfer([bidder3.account.address, linkAmount]);

        // Approve auction contract to spend LINK
        await linkContract.write.approve([auctionContract.address, linkAmount], {
            account: bidder1.account
        });
        await linkContract.write.approve([auctionContract.address, linkAmount], {
            account: bidder2.account
        });
        await linkContract.write.approve([auctionContract.address, linkAmount], {
            account: bidder3.account
        });

        // Approve NFT transfers
        await nftContract.write.setApprovalForAll([auctionContract.address, true], {
            account: seller.account
        });
    });

    describe("Contract Deployment", function () {
        it("Should deploy with correct initial state", async function () {
            const auctionAdmin = await auctionContract.read.admin();
            const fee = await auctionContract.read.fee();

            assert.equal(auctionAdmin.toLowerCase(), deployer.account.address);
            assert.equal(fee, FEE);
        });

        it("Should reject zero fee on deployment", async function () {
            try {
                await viem.deployContract("NftAuction", [
                    0n,
                    linkAddr,
                    ethUsdFeed,
                    linkUsdFeed
                ]);
                assert.fail("Should have rejected zero fee");
            } catch (error: any) {
                assert.match(error.message, /Fee must be positive/);
            }
        });

        it("Should reject invalid LINK address on deployment", async function () {
            try {
                await viem.deployContract("NftAuction", [
                    FEE,
                    "0x0000000000000000000000000000000000000000",
                    ethUsdFeed,
                    linkUsdFeed
                ]);
                assert.fail("Should have rejected invalid LINK address");
            } catch (error: any) {
                assert.match(error.message, /Invalid LINK address/);
            }
        });
    });

    describe("Auction Start", function () {
        it("Should start auction successfully", async function () {
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });

            const auctionInfo = await auctionContract.read.getAuctionInfo();
            const [auctionSeller, auctionNftAddr, nftId, endTime] = auctionInfo;

            assert.equal(auctionSeller.toLowerCase(), seller.account.address);
            assert.equal(auctionNftAddr.toLowerCase(), nftAddr);
            assert.equal(nftId, 1n);

            // Verify NFT was transferred to auction contract
            const nftOwner = await getNftOwner(1n);
            assert.equal(nftOwner.toLowerCase(), auctionContract.address.toLowerCase());
        });

        it("Should reject starting auction without fee", async function () {
            try {
                await auctionContract.write.startAuction([
                    nftAddr,
                    1n,
                    AUCTION_DURATION,
                    INITIAL_BID_VALUE
                ], {
                    account: seller.account,
                    value: 0n
                });
                assert.fail("Should have rejected insufficient fee");
            } catch (error: any) {
                assert.match(error.message, /Insufficient fee/);
            }
        });

        it("Should reject starting auction with invalid NFT", async function () {
            try {
                await auctionContract.write.startAuction([
                    "0x0000000000000000000000000000000000000000",
                    1n,
                    AUCTION_DURATION,
                    INITIAL_BID_VALUE
                ], {
                    account: seller.account,
                    value: FEE
                });
                assert.fail("Should have rejected invalid NFT address");
            } catch (error: any) {
                assert.match(error.message, /Invalid NFT address/);
            }
        });

        it("Should reject starting auction with too short duration", async function () {
            try {
                await auctionContract.write.startAuction([
                    nftAddr,
                    1n,
                    4, // 4 seconds - too short
                    INITIAL_BID_VALUE
                ], {
                    account: seller.account,
                    value: FEE
                });
                assert.fail("Should have rejected too short duration");
            } catch (error: any) {
                assert.match(error.message, /Duration too short/);
            }
        });

        it("Should reject starting multiple auctions", async function () {
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });

            try {
                await auctionContract.write.startAuction([
                    nftAddr,
                    2n,
                    AUCTION_DURATION,
                    INITIAL_BID_VALUE
                ], {
                    account: seller.account,
                    value: FEE
                });
                assert.fail("Should have rejected second auction");
            } catch (error: any) {
                assert.match(error.message, /Auction already started/);
            }
        });
    });

    describe("Bidding", function () {
        beforeEach(async function () {
            // Start auction before each bidding test
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });
        });

        it("Should accept ETH bids", async function () {
            const bidAmount = 1n * 10n ** ETH_DECIMALS; // 1 ETH

            const initialBalance = await getContractBalance(auctionContract.address);

            await auctionContract.write.bid({
                account: bidder1.account,
                value: bidAmount
            });

            const finalBalance = await getContractBalance(auctionContract.address);
            const bidInfo = await auctionContract.read.getBid([bidder1.account.address]);
            const auctionInfo = await auctionContract.read.getAuctionInfo();

            assert.equal(finalBalance - initialBalance, bidAmount);
            assert.equal(bidInfo[0], bidAmount); // ETH amount
            assert.equal(bidInfo[2] > INITIAL_BID_VALUE, true); // Total value > initial
            assert.equal(auctionInfo[4].toLowerCase(), bidder1.account.address); // Current winner
        });

        it("Should accept LINK bids", async function () {
            const bidAmount = 10n * 10n ** LINK_DECIMALS; // 10 LINK

            const initialLinkBalance = await getLinkBalance(auctionContract.address);

            await auctionContract.write.bidErc20Link([bidAmount], {
                account: bidder1.account
            });

            const finalLinkBalance = await getLinkBalance(auctionContract.address);
            const bidInfo = await auctionContract.read.getBid([bidder1.account.address]);
            const auctionInfo = await auctionContract.read.getAuctionInfo();

            assert.equal(finalLinkBalance - initialLinkBalance, bidAmount);
            assert.equal(bidInfo[1], bidAmount); // LINK amount
            assert.equal(bidInfo[2] > INITIAL_BID_VALUE, true); // Total value > initial
            assert.equal(auctionInfo[4].toLowerCase(), bidder1.account.address); // Current winner
        });

        it("Should update highest bid with higher ETH bid", async function () {
            // First bid
            await auctionContract.write.bid({
                account: bidder1.account,
                value: 1n * 10n ** ETH_DECIMALS
            });

            // Higher bid
            await auctionContract.write.bid({
                account: bidder2.account,
                value: 2n * 10n ** ETH_DECIMALS
            });

            const auctionInfo = await auctionContract.read.getAuctionInfo();
            assert.equal(auctionInfo[4].toLowerCase(), bidder2.account.address);
        });

        it("Should update highest bid with higher LINK bid", async function () {
            // First bid
            await auctionContract.write.bidErc20Link([10n * 10n ** LINK_DECIMALS], {
                account: bidder1.account
            });

            // Higher bid
            await auctionContract.write.bidErc20Link([20n * 10n ** LINK_DECIMALS], {
                account: bidder2.account
            });

            const auctionInfo = await auctionContract.read.getAuctionInfo();
            assert.equal(auctionInfo[4].toLowerCase(), bidder2.account.address);
        });

        it("Should combine ETH and LINK bids from same bidder", async function () {
            // First bid with ETH
            await auctionContract.write.bid({
                account: bidder1.account,
                value: 1n * 10n ** ETH_DECIMALS
            });

            const firstBidInfo = await auctionContract.read.getBid([bidder1.account.address]);
            const firstTotalValue = firstBidInfo[2];

            // Second bid with LINK from same bidder
            await auctionContract.write.bidErc20Link([10n * 10n ** LINK_DECIMALS], {
                account: bidder1.account
            });

            const finalBidInfo = await auctionContract.read.getBid([bidder1.account.address]);

            assert.equal(finalBidInfo[0], 1n * 10n ** ETH_DECIMALS); // ETH amount unchanged
            assert.equal(finalBidInfo[1], 10n * 10n ** LINK_DECIMALS); // LINK amount added
            assert.equal(finalBidInfo[2] > firstTotalValue, true); // Total value increased
        });

        it("Should reject bids below current highest", async function () {
            // High bid first
            await auctionContract.write.bid({
                account: bidder1.account,
                value: 2n * 10n ** ETH_DECIMALS
            });

            try {
                // Lower bid
                await auctionContract.write.bid({
                    account: bidder2.account,
                    value: 1n * 10n ** ETH_DECIMALS
                });
                assert.fail("Should have rejected low bid");
            } catch (error: any) {
                assert.match(error.message, /Bid too low/);
            }
        });

        it("Should reject zero ETH bids", async function () {
            try {
                await auctionContract.write.bid({
                    account: bidder1.account,
                    value: 0n
                });
                assert.fail("Should have rejected zero bid");
            } catch (error: any) {
                assert.match(error.message, /Bid must include ETH/);
            }
        });

        it("Should reject zero LINK bids", async function () {
            try {
                await auctionContract.write.bidErc20Link([0n], {
                    account: bidder1.account
                });
                assert.fail("Should have rejected zero LINK bid");
            } catch (error: any) {
                assert.match(error.message, /Bid amount must be positive/);
            }
        });

        it("Should reject bids after auction end", async function () {
            // Fast forward past auction end
            await increaseTime(AUCTION_DURATION + 1);

            try {
                await auctionContract.write.bid({
                    account: bidder1.account,
                    value: 1n * 10n ** ETH_DECIMALS
                });
                assert.fail("Should have rejected bid after auction end");
            } catch (error: any) {
                assert.match(error.message, /Auction ended/);
            }
        });
    });

    describe("Auction End", function () {
        beforeEach(async function () {
            // Start auction and place some bids
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });

            await auctionContract.write.bid({
                account: bidder1.account,
                value: 1n * 10n ** ETH_DECIMALS
            });

            await auctionContract.write.bidErc20Link([200n * 10n ** LINK_DECIMALS], {
                account: bidder2.account
            });

            await auctionContract.write.bid({
                account: bidder3.account,
                value: 2n * 10n ** ETH_DECIMALS
            });
        });

        it("Should end auction successfully with winner", async function () {
            // Fast forward to auction end
            await increaseTime(AUCTION_DURATION + 1);

            const initialSellerEth = await getContractBalance(seller.account.address);
            const initialSellerLink = await getLinkBalance(seller.account.address);

            await auctionContract.write.endAuction();

            const auctionInfo = await auctionContract.read.getAuctionInfo();
            const nftOwner = await getNftOwner(1n);
            const finalSellerEth = await getContractBalance(seller.account.address);
            const finalSellerLink = await getLinkBalance(seller.account.address);

            assert.equal(auctionInfo[6], true); // Auction ended
            assert.equal(nftOwner.toLowerCase(), bidder3.account.address); // NFT to highest bidder
            assert.equal(finalSellerEth > initialSellerEth, true); // Seller received ETH
        });

        it("Should end auction with no bids and return NFT to seller", async function () {
            // Start new auction without bids
            // Deploy auction contract
            const newAuction = await viem.deployContract("NftAuction", [
                FEE,
                linkAddr,
                ethUsdFeed,
                linkUsdFeed
            ]);
            await nftContract.write.setApprovalForAll([newAuction.address, true], {
                account: deployer.account
            });

            await newAuction.write.startAuction([
                nftAddr,
                2n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: deployer.account,
                value: FEE
            });

            await increaseTime(AUCTION_DURATION + 1);

            await newAuction.write.endAuction();

            const nftOwner = await getNftOwner(2n);
            assert.equal(nftOwner.toLowerCase(), deployer.account.address);
        });

        it("Should reject ending auction before time", async function () {
            try {
                await auctionContract.write.endAuction();
                assert.fail("Should have rejected early end");
            } catch (error: any) {
                assert.match(error.message, /Auction not ended/);
            }
        });

        it("Should reject ending auction twice", async function () {
            await increaseTime(AUCTION_DURATION + 1);
            await auctionContract.write.endAuction();

            try {
                await auctionContract.write.endAuction();
                assert.fail("Should have rejected second end");
            } catch (error: any) {
                assert.match(error.message, /Auction already finalized/);
            }
        });
    });

    describe("Withdrawals", function () {
        beforeEach(async function () {
            // Start auction and place multiple bids
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });

            await auctionContract.write.bid({
                account: bidder1.account,
                value: 1n * 10n ** ETH_DECIMALS
            });

            await auctionContract.write.bidErc20Link([200n * 10n ** LINK_DECIMALS], {
                account: bidder2.account
            });

            await auctionContract.write.bid({
                account: bidder3.account,
                value: 2n * 10n ** ETH_DECIMALS
            });

            // End auction
            await increaseTime(AUCTION_DURATION + 1);
            await auctionContract.write.endAuction();
        });

        it("Should reject winner withdrawal", async function () {
            try {
                await auctionContract.write.withdraw({
                    account: bidder3.account
                });
                assert.fail("Should have rejected winner withdrawal");
            } catch (error: any) {
                assert.match(error.message, /Winner cannot withdraw/);
            }
        });
    });

    describe("Emergency Functions", function () {
        it("Should reject emergency withdrawal by non-admin", async function () {
            await auctionContract.write.startAuction([
                nftAddr,
                1n,
                AUCTION_DURATION,
                INITIAL_BID_VALUE
            ], {
                account: seller.account,
                value: FEE
            });

            await increaseTime(AUCTION_DURATION + 1);

            try {
                await auctionContract.write.emergencyWithdraw({
                    account: bidder1.account
                });
                assert.fail("Should have rejected non-admin emergency withdrawal");
            } catch (error: any) {
                assert.match(error.message, /Only admin/);
            }
        });
    });
});