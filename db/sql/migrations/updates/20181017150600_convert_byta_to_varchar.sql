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


DROP TRIGGER protect_mem_accounts ON public.mem_accounts;
DROP FUNCTION public.revert_mem_account();

DROP VIEW public.full_blocks_list;
DROP VIEW public.trs_list;

DROP INDEX mem_accounts_get_delegates;

ALTER TABLE public.signatures
	ALTER COLUMN "publicKey" TYPE varchar(64) USING ENCODE("publicKey", 'hex');

ALTER TABLE public.mem_accounts
	ALTER COLUMN "publicKey" TYPE varchar(64) USING ENCODE("publicKey", 'hex');

ALTER TABLE public.rounds_rewards
	ALTER COLUMN "publicKey" TYPE varchar(64) USING ENCODE("publicKey", 'hex');

CREATE VIEW public.full_blocks_list AS
 SELECT b.id AS b_id,
    b.version AS b_version,
    b."timestamp" AS b_timestamp,
    b.height AS b_height,
    b."previousBlock" AS "b_previousBlock",
    b."numberOfTransactions" AS "b_numberOfTransactions",
    b."totalAmount" AS "b_totalAmount",
    b."totalFee" AS "b_totalFee",
    b.reward AS b_reward,
    b."payloadLength" AS "b_payloadLength",
    encode(b."payloadHash", 'hex'::text) AS "b_payloadHash",
    encode(b."generatorPublicKey", 'hex'::text) AS "b_generatorPublicKey",
    encode(b."blockSignature", 'hex'::text) AS "b_blockSignature",
    t.id AS t_id,
    t."rowId" AS "t_rowId",
    t.type AS t_type,
    t."timestamp" AS t_timestamp,
    encode(t."senderPublicKey", 'hex'::text) AS "t_senderPublicKey",
    t."senderId" AS "t_senderId",
    t."recipientId" AS "t_recipientId",
    t.amount AS t_amount,
    t.fee AS t_fee,
    encode(t.signature, 'hex'::text) AS t_signature,
    encode(t."signSignature", 'hex'::text) AS "t_signSignature",
    s."publicKey" AS "s_publicKey",
    d.username AS d_username,
    v.votes AS v_votes,
    m.min AS m_min,
    m.lifetime AS m_lifetime,
    m.keysgroup AS m_keysgroup,
    dapp.name AS dapp_name,
    dapp.description AS dapp_description,
    dapp.tags AS dapp_tags,
    dapp.type AS dapp_type,
    dapp.link AS dapp_link,
    dapp.category AS dapp_category,
    dapp.icon AS dapp_icon,
    it."dappId" AS "in_dappId",
    ot."dappId" AS "ot_dappId",
    ot."outTransactionId" AS "ot_outTransactionId",
    encode(t."requesterPublicKey", 'hex'::text) AS "t_requesterPublicKey",
    tf.data AS tf_data,
    t.signatures AS t_signatures
   FROM (((((((((public.blocks b
     LEFT JOIN public.trs t ON (((t."blockId")::text = (b.id)::text)))
     LEFT JOIN public.delegates d ON (((d."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.votes v ON (((v."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.signatures s ON (((s."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.multisignatures m ON (((m."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.dapps dapp ON (((dapp."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.intransfer it ON (((it."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.outtransfer ot ON (((ot."transactionId")::text = (t.id)::text)))
     LEFT JOIN public.transfer tf ON (((tf."transactionId")::text = (t.id)::text)));

ALTER TABLE public.full_blocks_list OWNER TO lisk;

CREATE VIEW public.trs_list AS
 SELECT t.id AS t_id,
    b.height AS b_height,
    t."blockId" AS "t_blockId",
    t.type AS t_type,
    t."timestamp" AS t_timestamp,
    t."senderPublicKey" AS "t_senderPublicKey",
    m."publicKey" AS "m_recipientPublicKey",
    upper((t."senderId")::text) AS "t_senderId",
    upper((t."recipientId")::text) AS "t_recipientId",
    t.amount AS t_amount,
    t.fee AS t_fee,
    encode(t.signature, 'hex'::text) AS t_signature,
    encode(t."signSignature", 'hex'::text) AS "t_SignSignature",
    t.signatures AS t_signatures,
    (( SELECT (blocks.height + 1)
           FROM public.blocks
          ORDER BY blocks.height DESC
         LIMIT 1) - b.height) AS confirmations,
    t."rowId" AS "t_rowId"
   FROM ((public.trs t
     LEFT JOIN public.blocks b ON (((t."blockId")::text = (b.id)::text)))
     LEFT JOIN public.mem_accounts m ON (((t."recipientId")::text = (m.address)::text)));


ALTER TABLE public.trs_list OWNER TO lisk;

CREATE FUNCTION public.revert_mem_account() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN IF NEW."address" <> OLD."address" THEN
		RAISE WARNING 'Reverting change of address from % to %', OLD."address", NEW."address";
		NEW."address" = OLD."address";
	END IF;
	IF NEW."u_username" <> OLD."u_username" AND NEW."u_username" IS NOT NULL AND OLD."u_username" IS NOT NULL THEN
		RAISE WARNING 'Reverting change of u_username from % to %', OLD."u_username", NEW."u_username";
		NEW."u_username" = OLD."u_username";
	END IF;
	IF NEW."username" <> OLD."username" AND NEW."username" IS NOT NULL AND OLD."username" IS NOT NULL THEN
		RAISE WARNING 'Reverting change of username from % to %', OLD."username", NEW."username";
		NEW."username" = OLD."username";
	END IF;
	IF NEW."publicKey" <> OLD."publicKey" AND OLD."publicKey" IS NOT NULL THEN
		RAISE WARNING 'Reverting change of publicKey from % to %', OLD."publicKey", NEW."publicKey";
		NEW."publicKey" = OLD."publicKey";
	END IF;
	IF NEW."secondPublicKey" <> OLD."secondPublicKey" AND OLD."secondPublicKey" IS NOT NULL THEN
		RAISE WARNING 'Reverting change of secondPublicKey from % to %', ENCODE(OLD."secondPublicKey", 'hex'), ENCODE(NEW."secondPublicKey", 'hex');
		NEW."secondPublicKey" = OLD."secondPublicKey";
	END IF;
	RETURN NEW;
	END $$;

ALTER FUNCTION public.revert_mem_account() OWNER TO lisk;

CREATE TRIGGER protect_mem_accounts BEFORE UPDATE ON public.mem_accounts FOR EACH ROW EXECUTE PROCEDURE public.revert_mem_account();

CREATE INDEX mem_accounts_get_delegates ON public.mem_accounts USING btree (vote DESC, "publicKey") WHERE ("isDelegate" = 1);
