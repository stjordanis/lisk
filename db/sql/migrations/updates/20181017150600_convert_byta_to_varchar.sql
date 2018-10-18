/*
* Copyright © 2018 Lisk Foundation
*
* See the LICENSE file at the top-level directory of this distribution
* for licensing information.
*
* Unless otherwise agreed in a custom licensing agreement with the Lisk Foundation,
* no part of this software, including this file, may be copied, modified,
* propagated, or distributed except according to the terms contained in the
* LICENSE file.
*
* Removal or modification of this copyright notice is prohibited.
*/


/*
DESCRIPTION: Rename column rate to rank, update current ranks, add index.

PARAMETERS: None
*/

-- SELECT * FROM mem_accounts;

DROP VIEW IF EXISTS trs_list;

ALTER TABLE mem_accounts ALTER COLUMN "publicKey" TYPE VARCHAR USING convert_from("publicKey", 'utf8');

CREATE OR REPLACE VIEW trs_list AS
	SELECT t."id" AS "t_id",
	       b."height" AS "b_height",
	       t."blockId" AS "t_blockId",
	       t."type" AS "t_type",
	       t."timestamp" AS "t_timestamp",
	       t."senderPublicKey" AS "t_senderPublicKey",
	       m."publicKey" AS "m_recipientPublicKey",
	       UPPER(t."senderId") AS "t_senderId",
	       UPPER(t."recipientId") AS "t_recipientId",
	       t."amount" AS "t_amount",
	       t."fee" AS "t_fee",
	       ENCODE(t."signature", 'hex') AS "t_signature",
	       ENCODE(t."signSignature", 'hex') AS "t_SignSignature",
	       t."signatures" AS "t_signatures",
	       (SELECT height + 1 FROM blocks ORDER BY height DESC LIMIT 1) - b."height" AS "confirmations",
	       t."rowId" AS "t_rowId"

	FROM trs t

	LEFT JOIN blocks b ON t."blockId" = b."id"
	LEFT JOIN mem_accounts m ON t."recipientId" = m."address";


DROP VIEW IF EXISTS full_blocks_list;

CREATE VIEW full_blocks_list AS
SELECT b."id" AS "b_id",
       b."version" AS "b_version",
       b."timestamp" AS "b_timestamp",
       b."height" AS "b_height",
       b."previousBlock" AS "b_previousBlock",
       b."numberOfTransactions" AS "b_numberOfTransactions",
       (b."totalAmount")::bigint AS "b_totalAmount",
       (b."totalFee")::bigint AS "b_totalFee",
       (b."reward")::bigint AS "b_reward",
       b."payloadLength" AS "b_payloadLength",
       ENCODE(b."payloadHash", 'hex') AS "b_payloadHash",
       ENCODE(b."generatorPublicKey", 'hex') AS "b_generatorPublicKey",
       ENCODE(b."blockSignature", 'hex') AS "b_blockSignature",
       t."id" AS "t_id",
       t."rowId" AS "t_rowId",
       t."type" AS "t_type",
       t."timestamp" AS "t_timestamp",
       ENCODE(t."senderPublicKey", 'hex') AS "t_senderPublicKey",
       t."senderId" AS "t_senderId",
       t."recipientId" AS "t_recipientId",
       (t."amount")::bigint AS "t_amount",
       (t."fee")::bigint AS "t_fee",
       ENCODE(t."signature", 'hex') AS "t_signature",
       ENCODE(t."signSignature", 'hex') AS "t_signSignature",
       s."publicKey" AS "s_publicKey",
       d."username" AS "d_username",
       v."votes" AS "v_votes",
       m."min" AS "m_min",
       m."lifetime" AS "m_lifetime",
       m."keysgroup" AS "m_keysgroup",
       dapp."name" AS "dapp_name",
       dapp."description" AS "dapp_description",
       dapp."tags" AS "dapp_tags",
       dapp."type" AS "dapp_type",
       dapp."link" AS "dapp_link",
       dapp."category" AS "dapp_category",
       dapp."icon" AS "dapp_icon",
       it."dappId" AS "in_dappId",
       ot."dappId" AS "ot_dappId",
       ot."outTransactionId" AS "ot_outTransactionId",
       ENCODE(t."requesterPublicKey", 'hex') AS "t_requesterPublicKey",
       t."signatures" AS "t_signatures"

FROM blocks b

LEFT OUTER JOIN trs AS t ON t."blockId" = b."id"
LEFT OUTER JOIN delegates AS d ON d."transactionId" = t."id"
LEFT OUTER JOIN votes AS v ON v."transactionId" = t."id"
LEFT OUTER JOIN signatures AS s ON s."transactionId" = t."id"
LEFT OUTER JOIN multisignatures AS m ON m."transactionId" = t."id"
LEFT OUTER JOIN dapps AS dapp ON dapp."transactionId" = t."id"
LEFT OUTER JOIN intransfer AS it ON it."transactionId" = t."id"
LEFT OUTER JOIN outtransfer AS ot ON ot."transactionId" = t."id";


CREATE OR REPLACE FUNCTION revert_mem_account() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$

BEGIN

  -- As per columns marked as immutable within application layer (logic/account.js).

  -- Revert any change of address
  IF NEW."address" <> OLD."address" THEN
    RAISE WARNING 'Reverting change of address from % to %', OLD."address", NEW."address";
    NEW."address" = OLD."address";
  END IF;

  -- Revert any change of u_username except of setting to null (see pop last block procedures)
  IF NEW."u_username" <> OLD."u_username" AND NEW."u_username" IS NOT NULL AND OLD."u_username" IS NOT NULL THEN
    RAISE WARNING 'Reverting change of u_username from % to %', OLD."u_username", NEW."u_username";
    NEW."u_username" = OLD."u_username";
  END IF;

  -- Revert any change of username except of setting to null (see pop last block procedures)
  IF NEW."username" <> OLD."username" AND NEW."username" IS NOT NULL AND OLD."username" IS NOT NULL THEN
    RAISE WARNING 'Reverting change of username from % to %', OLD."username", NEW."username";
    NEW."username" = OLD."username";
  END IF;

  -- Revert any change of publicKey
  -- And publicKey is already set
  IF NEW."publicKey" <> OLD."publicKey" AND OLD."publicKey" IS NOT NULL THEN
    RAISE WARNING 'Reverting change of publicKey from % to %', OLD."publicKey", NEW."publicKey";
    NEW."publicKey" = OLD."publicKey";
  END IF;

  -- Revert any change of secondPublicKey
  -- If secondPublicKey is already set
  IF NEW."secondPublicKey" <> OLD."secondPublicKey" AND OLD."secondPublicKey" IS NOT NULL THEN
    RAISE WARNING 'Reverting change of secondPublicKey from % to %', ENCODE(OLD."secondPublicKey", 'hex'),  ENCODE(NEW."secondPublicKey", 'hex');
    NEW."secondPublicKey" = OLD."secondPublicKey";
  END IF;

  RETURN NEW;

END $$;

DROP TRIGGER IF EXISTS protect_mem_accounts ON "mem_accounts";
CREATE TRIGGER protect_mem_accounts
  BEFORE UPDATE ON "mem_accounts" FOR EACH ROW
  EXECUTE PROCEDURE revert_mem_account();


-- Add 'mem_accounts_get_delegates' index for retrieving list of 101 delegates
DROP INDEX IF EXISTS "mem_accounts_get_delegates";
CREATE INDEX IF NOT EXISTS "mem_accounts_get_delegates" ON "mem_accounts" ("vote" DESC, "publicKey" ASC) WHERE "isDelegate" = 1;
