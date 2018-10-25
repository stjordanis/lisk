--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.4

-- Started on 2018-10-17 15:18:42 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


ALTER DATABASE lisk_dev OWNER TO mehmet;

\connect lisk_dev

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 13267)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3359 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 234 (class 1255 OID 236189)
-- Name: revert_mem_account(); Type: FUNCTION; Schema: public; Owner: lisk
--

CREATE FUNCTION public.revert_mem_account() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN IF NEW."address" <> OLD."address" THEN RAISE WARNING 'Reverting change of address from % to %', OLD."address", NEW."address"; NEW."address" = OLD."address"; END IF; IF NEW."u_username" <> OLD."u_username" AND NEW."u_username" IS NOT NULL AND OLD."u_username" IS NOT NULL THEN RAISE WARNING 'Reverting change of u_username from % to %', OLD."u_username", NEW."u_username"; NEW."u_username" = OLD."u_username"; END IF; IF NEW."username" <> OLD."username" AND NEW."username" IS NOT NULL AND OLD."username" IS NOT NULL THEN RAISE WARNING 'Reverting change of username from % to %', OLD."username", NEW."username"; NEW."username" = OLD."username"; END IF; IF NEW."publicKey" <> OLD."publicKey" AND OLD."publicKey" IS NOT NULL THEN RAISE WARNING 'Reverting change of publicKey from % to %', OLD."publicKey", NEW."publicKey"; NEW."publicKey" = OLD."publicKey"; END IF; IF NEW."secondPublicKey" <> OLD."secondPublicKey" AND OLD."secondPublicKey" IS NOT NULL THEN RAISE WARNING 'Reverting change of secondPublicKey from % to %', ENCODE(OLD."secondPublicKey", 'hex'), ENCODE(NEW."secondPublicKey", 'hex'); NEW."secondPublicKey" = OLD."secondPublicKey"; END IF; RETURN NEW; END $$;


ALTER FUNCTION public.revert_mem_account() OWNER TO lisk;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 198 (class 1259 OID 235915)
-- Name: blocks; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.blocks (
    id character varying(20) NOT NULL,
    "rowId" integer NOT NULL,
    version integer NOT NULL,
    "timestamp" integer NOT NULL,
    height integer NOT NULL,
    "previousBlock" character varying(20),
    "numberOfTransactions" integer NOT NULL,
    "totalAmount" bigint NOT NULL,
    "totalFee" bigint NOT NULL,
    reward bigint NOT NULL,
    "payloadLength" integer NOT NULL,
    "payloadHash" bytea NOT NULL,
    "generatorPublicKey" bytea NOT NULL,
    "blockSignature" bytea NOT NULL
);


ALTER TABLE public.blocks OWNER TO lisk;

--
-- TOC entry 211 (class 1259 OID 236067)
-- Name: blocks_list; Type: VIEW; Schema: public; Owner: lisk
--

CREATE VIEW public.blocks_list AS
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
    (( SELECT (max(blocks.height) + 1)
           FROM public.blocks) - b.height) AS b_confirmations
   FROM public.blocks b;


ALTER TABLE public.blocks_list OWNER TO lisk;

--
-- TOC entry 197 (class 1259 OID 235913)
-- Name: blocks_rowId_seq; Type: SEQUENCE; Schema: public; Owner: lisk
--

CREATE SEQUENCE public."blocks_rowId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."blocks_rowId_seq" OWNER TO lisk;

--
-- TOC entry 3360 (class 0 OID 0)
-- Dependencies: 197
-- Name: blocks_rowId_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lisk
--

ALTER SEQUENCE public."blocks_rowId_seq" OWNED BY public.blocks."rowId";


--
-- TOC entry 206 (class 1259 OID 235994)
-- Name: dapps; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.dapps (
    "transactionId" character varying(20) NOT NULL,
    name character varying(32) NOT NULL,
    description character varying(160),
    tags character varying(160),
    link text,
    type integer NOT NULL,
    category integer NOT NULL,
    icon text
);


ALTER TABLE public.dapps OWNER TO lisk;

--
-- TOC entry 202 (class 1259 OID 235958)
-- Name: delegates; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.delegates (
    username character varying(20) NOT NULL,
    "transactionId" character varying(20) NOT NULL
);


ALTER TABLE public.delegates OWNER TO lisk;

--
-- TOC entry 204 (class 1259 OID 235977)
-- Name: forks_stat; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.forks_stat (
    "delegatePublicKey" bytea NOT NULL,
    "blockTimestamp" integer NOT NULL,
    "blockId" character varying(20) NOT NULL,
    "blockHeight" integer NOT NULL,
    "previousBlock" character varying(20) NOT NULL,
    cause integer NOT NULL
);


ALTER TABLE public.forks_stat OWNER TO lisk;

--
-- TOC entry 207 (class 1259 OID 236005)
-- Name: intransfer; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.intransfer (
    "dappId" character varying(20) NOT NULL,
    "transactionId" character varying(20) NOT NULL
);


ALTER TABLE public.intransfer OWNER TO lisk;

--
-- TOC entry 205 (class 1259 OID 235983)
-- Name: multisignatures; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.multisignatures (
    min integer NOT NULL,
    lifetime integer NOT NULL,
    keysgroup text NOT NULL,
    "transactionId" character varying(20) NOT NULL
);


ALTER TABLE public.multisignatures OWNER TO lisk;

--
-- TOC entry 208 (class 1259 OID 236013)
-- Name: outtransfer; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.outtransfer (
    "transactionId" character varying(20) NOT NULL,
    "dappId" character varying(20) NOT NULL,
    "outTransactionId" character varying(20) NOT NULL
);


ALTER TABLE public.outtransfer OWNER TO lisk;

--
-- TOC entry 201 (class 1259 OID 235945)
-- Name: signatures; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.signatures (
    "transactionId" character varying(20) NOT NULL,
    "publicKey" varchar(64) NOT NULL
);


ALTER TABLE public.signatures OWNER TO lisk;

--
-- TOC entry 219 (class 1259 OID 236254)
-- Name: transfer; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.transfer (
    data bytea NOT NULL,
    "transactionId" character varying(20) NOT NULL
);


ALTER TABLE public.transfer OWNER TO lisk;

--
-- TOC entry 200 (class 1259 OID 235931)
-- Name: trs; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.trs (
    id character varying(20) NOT NULL,
    "rowId" integer NOT NULL,
    "blockId" character varying(20) NOT NULL,
    type smallint NOT NULL,
    "timestamp" integer NOT NULL,
    "senderPublicKey" bytea NOT NULL,
    "senderId" character varying(22) NOT NULL,
    "recipientId" character varying(22),
    amount bigint NOT NULL,
    fee bigint NOT NULL,
    signature bytea NOT NULL,
    "signSignature" bytea,
    "requesterPublicKey" bytea,
    signatures text
);


ALTER TABLE public.trs OWNER TO lisk;

--
-- TOC entry 203 (class 1259 OID 235966)
-- Name: votes; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.votes (
    votes text,
    "transactionId" character varying(20) NOT NULL
);


ALTER TABLE public.votes OWNER TO lisk;

--
-- TOC entry 221 (class 1259 OID 236306)
-- Name: full_blocks_list; Type: VIEW; Schema: public; Owner: lisk
--

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

--
-- TOC entry 212 (class 1259 OID 236082)
-- Name: mem_accounts; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_accounts (
    username character varying(20),
    "isDelegate" smallint DEFAULT 0,
    "u_isDelegate" smallint DEFAULT 0,
    "secondSignature" smallint DEFAULT 0,
    "u_secondSignature" smallint DEFAULT 0,
    u_username character varying(20),
    address character varying(22) NOT NULL,
    "publicKey" varchar(64),
    "secondPublicKey" bytea,
    balance bigint DEFAULT 0,
    u_balance bigint DEFAULT 0,
    vote bigint DEFAULT 0,
    rank bigint,
    delegates text,
    u_delegates text,
    multisignatures text,
    u_multisignatures text,
    multimin smallint DEFAULT 0,
    u_multimin smallint DEFAULT 0,
    multilifetime smallint DEFAULT 0,
    u_multilifetime smallint DEFAULT 0,
    nameexist smallint DEFAULT 0,
    u_nameexist smallint DEFAULT 0,
    "producedBlocks" integer DEFAULT 0,
    "missedBlocks" integer DEFAULT 0,
    fees bigint DEFAULT 0,
    rewards bigint DEFAULT 0
);


ALTER TABLE public.mem_accounts OWNER TO lisk;

--
-- TOC entry 214 (class 1259 OID 236112)
-- Name: mem_accounts2delegates; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_accounts2delegates (
    "accountId" character varying(22) NOT NULL,
    "dependentId" character varying(64) NOT NULL
);


ALTER TABLE public.mem_accounts2delegates OWNER TO lisk;

--
-- TOC entry 216 (class 1259 OID 236128)
-- Name: mem_accounts2multisignatures; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_accounts2multisignatures (
    "accountId" character varying(22) NOT NULL,
    "dependentId" character varying(64) NOT NULL
);


ALTER TABLE public.mem_accounts2multisignatures OWNER TO lisk;

--
-- TOC entry 215 (class 1259 OID 236120)
-- Name: mem_accounts2u_delegates; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_accounts2u_delegates (
    "accountId" character varying(22) NOT NULL,
    "dependentId" character varying(64) NOT NULL
);


ALTER TABLE public.mem_accounts2u_delegates OWNER TO lisk;

--
-- TOC entry 217 (class 1259 OID 236136)
-- Name: mem_accounts2u_multisignatures; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_accounts2u_multisignatures (
    "accountId" character varying(22) NOT NULL,
    "dependentId" character varying(64) NOT NULL
);


ALTER TABLE public.mem_accounts2u_multisignatures OWNER TO lisk;

--
-- TOC entry 213 (class 1259 OID 236109)
-- Name: mem_round; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.mem_round (
    address character varying(22),
    amount bigint,
    delegate character varying(64),
    round integer
);


ALTER TABLE public.mem_round OWNER TO lisk;

--
-- TOC entry 196 (class 1259 OID 235905)
-- Name: migrations; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.migrations (
    id character varying(22) NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.migrations OWNER TO lisk;

--
-- TOC entry 210 (class 1259 OID 236025)
-- Name: peers; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.peers (
    id integer NOT NULL,
    ip inet NOT NULL,
    "wsPort" smallint NOT NULL,
    state smallint NOT NULL,
    os character varying(64),
    version character varying(64),
    clock bigint,
    broadhash bytea,
    height integer
);


ALTER TABLE public.peers OWNER TO lisk;

--
-- TOC entry 209 (class 1259 OID 236023)
-- Name: peers_id_seq; Type: SEQUENCE; Schema: public; Owner: lisk
--

CREATE SEQUENCE public.peers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.peers_id_seq OWNER TO lisk;

--
-- TOC entry 3361 (class 0 OID 0)
-- Dependencies: 209
-- Name: peers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lisk
--

ALTER SEQUENCE public.peers_id_seq OWNED BY public.peers.id;


--
-- TOC entry 220 (class 1259 OID 236272)
-- Name: rounds_rewards; Type: TABLE; Schema: public; Owner: lisk
--

CREATE TABLE public.rounds_rewards (
    "timestamp" integer NOT NULL,
    fees bigint NOT NULL,
    reward bigint NOT NULL,
    round integer NOT NULL,
    "publicKey" varchar(64) NOT NULL
);


ALTER TABLE public.rounds_rewards OWNER TO lisk;

--
-- TOC entry 218 (class 1259 OID 236245)
-- Name: trs_list; Type: VIEW; Schema: public; Owner: lisk
--

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

--
-- TOC entry 199 (class 1259 OID 235929)
-- Name: trs_rowId_seq; Type: SEQUENCE; Schema: public; Owner: lisk
--

CREATE SEQUENCE public."trs_rowId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."trs_rowId_seq" OWNER TO lisk;

--
-- TOC entry 3362 (class 0 OID 0)
-- Dependencies: 199
-- Name: trs_rowId_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lisk
--

ALTER SEQUENCE public."trs_rowId_seq" OWNED BY public.trs."rowId";


--
-- TOC entry 3117 (class 2604 OID 235918)
-- Name: blocks rowId; Type: DEFAULT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.blocks ALTER COLUMN "rowId" SET DEFAULT nextval('public."blocks_rowId_seq"'::regclass);


--
-- TOC entry 3119 (class 2604 OID 236028)
-- Name: peers id; Type: DEFAULT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.peers ALTER COLUMN id SET DEFAULT nextval('public.peers_id_seq'::regclass);


--
-- TOC entry 3118 (class 2604 OID 235934)
-- Name: trs rowId; Type: DEFAULT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.trs ALTER COLUMN "rowId" SET DEFAULT nextval('public."trs_rowId_seq"'::regclass);


--
-- TOC entry 3187 (class 2606 OID 236198)
-- Name: peers address_unique; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.peers
    ADD CONSTRAINT address_unique UNIQUE (ip, "wsPort");


--
-- TOC entry 3143 (class 2606 OID 235923)
-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (id);


--
-- TOC entry 3180 (class 2606 OID 236297)
-- Name: dapps dapps_transactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.dapps
    ADD CONSTRAINT "dapps_transactionId_key" UNIQUE ("transactionId");


--
-- TOC entry 3173 (class 2606 OID 236253)
-- Name: delegates delegates_unique; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.delegates
    ADD CONSTRAINT delegates_unique UNIQUE (username, "transactionId");


--
-- TOC entry 3182 (class 2606 OID 236303)
-- Name: intransfer intransfer_transactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.intransfer
    ADD CONSTRAINT "intransfer_transactionId_key" UNIQUE ("transactionId");


--
-- TOC entry 3199 (class 2606 OID 236107)
-- Name: mem_accounts mem_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.mem_accounts
    ADD CONSTRAINT mem_accounts_pkey PRIMARY KEY (address);


--
-- TOC entry 3138 (class 2606 OID 235912)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3177 (class 2606 OID 236305)
-- Name: multisignatures multisignatures_transactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.multisignatures
    ADD CONSTRAINT "multisignatures_transactionId_key" UNIQUE ("transactionId");


--
-- TOC entry 3185 (class 2606 OID 236017)
-- Name: outtransfer outtransfer_outTransactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.outtransfer
    ADD CONSTRAINT "outtransfer_outTransactionId_key" UNIQUE ("outTransactionId");


--
-- TOC entry 3191 (class 2606 OID 236033)
-- Name: peers peers_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.peers
    ADD CONSTRAINT peers_pkey PRIMARY KEY (id);


--
-- TOC entry 3169 (class 2606 OID 235952)
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY ("transactionId");


--
-- TOC entry 3208 (class 2606 OID 236301)
-- Name: transfer transfer_transactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT "transfer_transactionId_key" UNIQUE ("transactionId");


--
-- TOC entry 3157 (class 2606 OID 235939)
-- Name: trs trs_pkey; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.trs
    ADD CONSTRAINT trs_pkey PRIMARY KEY (id);


--
-- TOC entry 3175 (class 2606 OID 236299)
-- Name: votes votes_transactionId_key; Type: CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT "votes_transactionId_key" UNIQUE ("transactionId");


--
-- TOC entry 3139 (class 1259 OID 236048)
-- Name: blocks_generator_public_key; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX blocks_generator_public_key ON public.blocks USING btree ("generatorPublicKey");


--
-- TOC entry 3140 (class 1259 OID 236042)
-- Name: blocks_height; Type: INDEX; Schema: public; Owner: lisk
--

CREATE UNIQUE INDEX blocks_height ON public.blocks USING btree (height);


--
-- TOC entry 3141 (class 1259 OID 236052)
-- Name: blocks_numberOfTransactions; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "blocks_numberOfTransactions" ON public.blocks USING btree ("numberOfTransactions");


--
-- TOC entry 3144 (class 1259 OID 236043)
-- Name: blocks_previousBlock; Type: INDEX; Schema: public; Owner: lisk
--

CREATE UNIQUE INDEX "blocks_previousBlock" ON public.blocks USING btree ("previousBlock");


--
-- TOC entry 3145 (class 1259 OID 236049)
-- Name: blocks_reward; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX blocks_reward ON public.blocks USING btree (reward);


--
-- TOC entry 3146 (class 1259 OID 236209)
-- Name: blocks_rounds; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX blocks_rounds ON public.blocks USING btree (((ceil(((height)::double precision / (101)::double precision)))::integer));


--
-- TOC entry 3147 (class 1259 OID 236047)
-- Name: blocks_rowId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "blocks_rowId" ON public.blocks USING btree ("rowId");


--
-- TOC entry 3148 (class 1259 OID 236053)
-- Name: blocks_timestamp; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX blocks_timestamp ON public.blocks USING btree ("timestamp");


--
-- TOC entry 3149 (class 1259 OID 236051)
-- Name: blocks_totalAmount; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "blocks_totalAmount" ON public.blocks USING btree ("totalAmount");


--
-- TOC entry 3150 (class 1259 OID 236050)
-- Name: blocks_totalFee; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "blocks_totalFee" ON public.blocks USING btree ("totalFee");


--
-- TOC entry 3178 (class 1259 OID 236066)
-- Name: dapps_name; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX dapps_name ON public.dapps USING btree (name);


--
-- TOC entry 3171 (class 1259 OID 236063)
-- Name: delegates_trs_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX delegates_trs_id ON public.delegates USING btree ("transactionId");


--
-- TOC entry 3202 (class 1259 OID 236193)
-- Name: mem_accounts2delegates_accountId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "mem_accounts2delegates_accountId" ON public.mem_accounts2delegates USING btree ("accountId");


--
-- TOC entry 3203 (class 1259 OID 236237)
-- Name: mem_accounts2delegates_depId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "mem_accounts2delegates_depId" ON public.mem_accounts2delegates USING btree ("dependentId");


--
-- TOC entry 3205 (class 1259 OID 236195)
-- Name: mem_accounts2multisignatures_accountId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "mem_accounts2multisignatures_accountId" ON public.mem_accounts2multisignatures USING btree ("accountId");


--
-- TOC entry 3204 (class 1259 OID 236194)
-- Name: mem_accounts2u_delegates_accountId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "mem_accounts2u_delegates_accountId" ON public.mem_accounts2u_delegates USING btree ("accountId");


--
-- TOC entry 3206 (class 1259 OID 236196)
-- Name: mem_accounts2u_multisignatures_accountId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "mem_accounts2u_multisignatures_accountId" ON public.mem_accounts2u_multisignatures USING btree ("accountId");


--
-- TOC entry 3192 (class 1259 OID 236204)
-- Name: mem_accounts_address; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_address ON public.mem_accounts USING btree (address);


--
-- TOC entry 3193 (class 1259 OID 236205)
-- Name: mem_accounts_address_upper; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_address_upper ON public.mem_accounts USING btree (upper((address)::text));


--
-- TOC entry 3194 (class 1259 OID 236108)
-- Name: mem_accounts_balance; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_balance ON public.mem_accounts USING btree (balance);


--
-- TOC entry 3195 (class 1259 OID 236311)
-- Name: mem_accounts_delegate_rank; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_delegate_rank ON public.mem_accounts USING btree (rank) WHERE ("isDelegate" = 1);


--
-- TOC entry 3196 (class 1259 OID 236207)
-- Name: mem_accounts_get_delegates; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_get_delegates ON public.mem_accounts USING btree (vote DESC, "publicKey") WHERE ("isDelegate" = 1);


--
-- TOC entry 3197 (class 1259 OID 236206)
-- Name: mem_accounts_is_delegate; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_accounts_is_delegate ON public.mem_accounts USING btree ("isDelegate");


--
-- TOC entry 3200 (class 1259 OID 236191)
-- Name: mem_round_address; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_round_address ON public.mem_round USING btree (address);


--
-- TOC entry 3201 (class 1259 OID 236282)
-- Name: mem_round_round; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX mem_round_round ON public.mem_round USING btree (round);


--
-- TOC entry 3183 (class 1259 OID 236044)
-- Name: out_transaction_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE UNIQUE INDEX out_transaction_id ON public.outtransfer USING btree ("outTransactionId");


--
-- TOC entry 3188 (class 1259 OID 236197)
-- Name: peers_broadhash; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX peers_broadhash ON public.peers USING btree (broadhash);


--
-- TOC entry 3189 (class 1259 OID 236271)
-- Name: peers_height; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX peers_height ON public.peers USING btree (height);


--
-- TOC entry 3209 (class 1259 OID 236280)
-- Name: rounds_rewards_public_key; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX rounds_rewards_public_key ON public.rounds_rewards USING btree ("publicKey");


--
-- TOC entry 3210 (class 1259 OID 236279)
-- Name: rounds_rewards_round; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX rounds_rewards_round ON public.rounds_rewards USING btree (round);


--
-- TOC entry 3211 (class 1259 OID 236278)
-- Name: rounds_rewards_timestamp; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX rounds_rewards_timestamp ON public.rounds_rewards USING btree ("timestamp");


--
-- TOC entry 3170 (class 1259 OID 236061)
-- Name: signatures_trs_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX signatures_trs_id ON public.signatures USING btree ("transactionId");


--
-- TOC entry 3151 (class 1259 OID 236290)
-- Name: trs_amount_asc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_amount_asc_row_id_asc ON public.trs USING btree (amount, "rowId");


--
-- TOC entry 3152 (class 1259 OID 236291)
-- Name: trs_amount_desc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_amount_desc_row_id_asc ON public.trs USING btree (amount DESC, "rowId");


--
-- TOC entry 3153 (class 1259 OID 236055)
-- Name: trs_block_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_block_id ON public.trs USING btree ("blockId");


--
-- TOC entry 3154 (class 1259 OID 236292)
-- Name: trs_fee_asc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_fee_asc_row_id_asc ON public.trs USING btree (fee, "rowId");


--
-- TOC entry 3155 (class 1259 OID 236293)
-- Name: trs_fee_desc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_fee_desc_row_id_asc ON public.trs USING btree (fee DESC, "rowId");


--
-- TOC entry 3158 (class 1259 OID 236057)
-- Name: trs_recipient_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_recipient_id ON public.trs USING btree ("recipientId");


--
-- TOC entry 3159 (class 1259 OID 236054)
-- Name: trs_rowId; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "trs_rowId" ON public.trs USING btree ("rowId");


--
-- TOC entry 3160 (class 1259 OID 236058)
-- Name: trs_senderPublicKey; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX "trs_senderPublicKey" ON public.trs USING btree ("senderPublicKey");


--
-- TOC entry 3161 (class 1259 OID 236056)
-- Name: trs_sender_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_sender_id ON public.trs USING btree ("senderId");


--
-- TOC entry 3162 (class 1259 OID 236288)
-- Name: trs_timestamp_asc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_timestamp_asc_row_id_asc ON public.trs USING btree ("timestamp", "rowId");


--
-- TOC entry 3163 (class 1259 OID 236289)
-- Name: trs_timestamp_desc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_timestamp_desc_row_id_asc ON public.trs USING btree ("timestamp" DESC, "rowId");


--
-- TOC entry 3164 (class 1259 OID 236294)
-- Name: trs_type_asc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_type_asc_row_id_asc ON public.trs USING btree (type, "rowId");


--
-- TOC entry 3165 (class 1259 OID 236295)
-- Name: trs_type_desc_row_id_asc; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_type_desc_row_id_asc ON public.trs USING btree (type DESC, "rowId");


--
-- TOC entry 3166 (class 1259 OID 236251)
-- Name: trs_upper_recipient_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_upper_recipient_id ON public.trs USING btree (upper(("recipientId")::text));


--
-- TOC entry 3167 (class 1259 OID 236250)
-- Name: trs_upper_sender_id; Type: INDEX; Schema: public; Owner: lisk
--

CREATE INDEX trs_upper_sender_id ON public.trs USING btree (upper(("senderId")::text));


--
-- TOC entry 3226 (class 2620 OID 236190)
-- Name: mem_accounts protect_mem_accounts; Type: TRIGGER; Schema: public; Owner: lisk
--

CREATE TRIGGER protect_mem_accounts BEFORE UPDATE ON public.mem_accounts FOR EACH ROW EXECUTE PROCEDURE public.revert_mem_account();


--
-- TOC entry 3212 (class 2606 OID 235924)
-- Name: blocks blocks_previousBlock_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT "blocks_previousBlock_fkey" FOREIGN KEY ("previousBlock") REFERENCES public.blocks(id) ON DELETE SET NULL;


--
-- TOC entry 3218 (class 2606 OID 236000)
-- Name: dapps dapps_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.dapps
    ADD CONSTRAINT "dapps_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3215 (class 2606 OID 235961)
-- Name: delegates delegates_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.delegates
    ADD CONSTRAINT "delegates_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3219 (class 2606 OID 236008)
-- Name: intransfer intransfer_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.intransfer
    ADD CONSTRAINT "intransfer_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3221 (class 2606 OID 236115)
-- Name: mem_accounts2delegates mem_accounts2delegates_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.mem_accounts2delegates
    ADD CONSTRAINT "mem_accounts2delegates_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public.mem_accounts(address) ON DELETE CASCADE;


--
-- TOC entry 3223 (class 2606 OID 236131)
-- Name: mem_accounts2multisignatures mem_accounts2multisignatures_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.mem_accounts2multisignatures
    ADD CONSTRAINT "mem_accounts2multisignatures_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public.mem_accounts(address) ON DELETE CASCADE;


--
-- TOC entry 3222 (class 2606 OID 236123)
-- Name: mem_accounts2u_delegates mem_accounts2u_delegates_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.mem_accounts2u_delegates
    ADD CONSTRAINT "mem_accounts2u_delegates_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public.mem_accounts(address) ON DELETE CASCADE;


--
-- TOC entry 3224 (class 2606 OID 236139)
-- Name: mem_accounts2u_multisignatures mem_accounts2u_multisignatures_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.mem_accounts2u_multisignatures
    ADD CONSTRAINT "mem_accounts2u_multisignatures_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public.mem_accounts(address) ON DELETE CASCADE;


--
-- TOC entry 3217 (class 2606 OID 235989)
-- Name: multisignatures multisignatures_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.multisignatures
    ADD CONSTRAINT "multisignatures_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3220 (class 2606 OID 236018)
-- Name: outtransfer outtransfer_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.outtransfer
    ADD CONSTRAINT "outtransfer_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3214 (class 2606 OID 235953)
-- Name: signatures signatures_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT "signatures_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3225 (class 2606 OID 236260)
-- Name: transfer transfer_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT "transfer_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3213 (class 2606 OID 235940)
-- Name: trs trs_blockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.trs
    ADD CONSTRAINT "trs_blockId_fkey" FOREIGN KEY ("blockId") REFERENCES public.blocks(id) ON DELETE CASCADE;


--
-- TOC entry 3216 (class 2606 OID 235972)
-- Name: votes votes_transactionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lisk
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT "votes_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES public.trs(id) ON DELETE CASCADE;


--
-- TOC entry 3358 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: mehmet
--

GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2018-10-17 15:18:42 CEST

--
-- PostgreSQL database dump complete
--

