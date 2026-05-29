import { workflow, node, trigger, ifElse, expr } from '@n8n/workflow-sdk';

const SECRET = 'bj6VFq3FcdWYVl4Mv-3_fDSbGesnSfjHdVOq8VoFqfshrZo0W7x3tZPHTztc-3sl';
const MS_TOKEN = 'Bearer ms-ca592d9a-ec9b-4052-ad94-0bb6433aaec4';

const authQuery =
  "WITH input AS (\n" +
  "  SELECT nullif($1,'__NULL__')::text AS raw,\n" +
  "         nullif($2,'__NULL__')::text AS sid,\n" +
  "         nullif($3,'__NULL__')::text AS img,\n" +
  "         '" + SECRET + "'::text AS secret\n" +
  "),\n" +
  "parts AS (\n" +
  "  SELECT i.secret, i.sid, i.img,\n" +
  "    split_part(coalesce(i.raw,''),'.',1) AS h,\n" +
  "    split_part(coalesce(i.raw,''),'.',2) AS p,\n" +
  "    split_part(coalesce(i.raw,''),'.',3) AS sig,\n" +
  "    coalesce(i.raw,'') AS raw\n" +
  "  FROM input i\n" +
  "),\n" +
  "verify AS (\n" +
  "  SELECT pa.p, pa.sid, pa.img,\n" +
  "    (pa.raw <> '' AND pa.sig = replace(replace(translate(encode(hmac(pa.h||'.'||pa.p, pa.secret,'sha256'),'base64'),'+/','-_'),'=',''), E'\\n','')) AS sig_ok\n" +
  "  FROM parts pa\n" +
  "),\n" +
  "claims AS (\n" +
  "  SELECT v.sig_ok, v.sid, v.img,\n" +
  "    CASE WHEN v.sig_ok THEN convert_from(decode(translate(v.p,'-_','+/')||repeat('=',(4-length(v.p)%4)%4),'base64'),'UTF8')::json END AS payload\n" +
  "  FROM verify v\n" +
  "),\n" +
  "final AS (\n" +
  "  SELECT (c.sig_ok AND (c.payload->>'exp')::bigint > extract(epoch from now())::bigint) AS auth_ok,\n" +
  "    (c.payload->>'sub') AS uid, c.sid, c.img\n" +
  "  FROM claims c\n" +
  "),\n" +
  "src2 AS ( SELECT nullif($4,'__NULL__')::text AS user_text ),\n" +
  "sess AS (\n" +
  "  INSERT INTO chat_sessions (id, user_id)\n" +
  "  SELECT f.sid, f.uid::uuid FROM final f WHERE f.auth_ok AND f.sid IS NOT NULL\n" +
  "  ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id\n" +
  "  RETURNING id\n" +
  "),\n" +
  "ins_user AS (\n" +
  "  INSERT INTO chat_messages (session_id, author, type, image_path, text)\n" +
  "  SELECT f.sid, 'user', 'image', f.img, (SELECT user_text FROM src2)\n" +
  "  FROM final f WHERE f.auth_ok AND f.sid IS NOT NULL AND f.img IS NOT NULL\n" +
  "  RETURNING id\n" +
  ")\n" +
  "SELECT\n" +
  "  CASE WHEN f.auth_ok THEN 200 ELSE 401 END AS \"statusCode\",\n" +
  "  f.sid AS session_id, f.img AS image_url, (SELECT user_text FROM src2) AS user_text\n" +
  "FROM final f;";

const visionText =
  "\"Analise a foto deste ambiente.\" + ($json.user_text ? (\" O cliente tambem escreveu: \\\"\" + $json.user_text + \"\\\". Leve isso em conta com prioridade.\") : \"\") + \" Responda APENAS um JSON valido: {\\\"room\\\":\\\"bedroom|living|kitchen|bathroom|external|office|diningRoom\\\",\\\"light_temperature\\\":\\\"warm|neutral|cool\\\",\\\"brightness_level\\\":\\\"soft|medium|intense\\\",\\\"wants_rgb\\\":false,\\\"categories\\\":[],\\\"rationale\\\":\\\"1 frase em PT-BR sobre o ambiente e a luz ideal\\\",\\\"confident\\\":true}. Regras: defina wants_rgb=true se o cliente pediu luz colorida/RGB/gamer. Em 'categories' liste 0 a 2 tipos desejados dentre [strip,panel,spot,pendant,floorLamp,lamp,walllamp,smart,track] se o cliente indicar preferencia (ex: fita->strip). quarto/sala tendem a warm/soft; cozinha/escritorio/banheiro tendem a neutral/cool, medium/intense. confident=false se a foto nao for de um comodo identificavel.\"";

const visionBody =
  "={{ JSON.stringify({\n" +
  "  model: \"Qwen/Qwen2.5-VL-72B-Instruct\",\n" +
  "  messages: [\n" +
  "    { role: \"user\", content: [\n" +
  "      { type: \"text\", text: " + visionText + " },\n" +
  "      { type: \"image_url\", image_url: { url: (typeof $json.image_url === \"string\" && $json.image_url.includes(\"/upload/\") && $json.image_url.includes(\"res.cloudinary.com\")) ? $json.image_url.replace(\"/upload/\",\"/upload/w_1024,h_1024,c_limit/\") : $json.image_url } }\n" +
  "    ] }\n" +
  "  ]\n" +
  "}) }}";

const recommendQuery =
  "WITH g AS (\n" +
  "  SELECT nullif($1,'__NULL__')::text AS sid,\n" +
  "         coalesce(nullif($2,'__NULL__'),'') AS raw_json\n" +
  "),\n" +
  "parsed AS (\n" +
  "  SELECT g.sid, (regexp_match(g.raw_json, '\\{[\\s\\S]*\\}'))[1] AS j FROM g\n" +
  "),\n" +
  "vis AS (\n" +
  "  SELECT p.sid,\n" +
  "    coalesce(p.j::json->>'room','') AS room,\n" +
  "    coalesce(p.j::json->>'light_temperature','') AS temp,\n" +
  "    coalesce(p.j::json->>'brightness_level','') AS bright,\n" +
  "    coalesce((p.j::json->>'wants_rgb')::boolean, false) AS wants_rgb,\n" +
  "    CASE WHEN p.j::json->'categories' IS NULL THEN ARRAY[]::text[]\n" +
  "         ELSE ARRAY(SELECT lower(json_array_elements_text(p.j::json->'categories'))) END AS cats,\n" +
  "    coalesce(p.j::json->>'rationale','Recomendo estas opcoes pro seu ambiente.') AS rationale,\n" +
  "    coalesce((p.j::json->>'confident')::boolean, false) AS confident\n" +
  "  FROM parsed p\n" +
  "),\n" +
  "scored AS (\n" +
  "  SELECT v.sid, v.rationale, v.confident, v.wants_rgb,\n" +
  "    pr.id,\n" +
  "    ( (CASE WHEN v.room <> '' AND v.room = ANY(pr.ideal_rooms) THEN 3 ELSE 0 END)\n" +
  "    + (CASE WHEN v.temp <> '' AND pr.light_temperature = v.temp THEN 2 ELSE 0 END)\n" +
  "    + (CASE WHEN v.bright <> '' AND pr.brightness_level = v.bright THEN 1 ELSE 0 END)\n" +
  "    + (CASE WHEN array_length(v.cats,1) > 0 AND lower(pr.category) = ANY(v.cats) THEN 4 ELSE 0 END)\n" +
  "    + (CASE WHEN v.wants_rgb AND (\n" +
  "         pr.name ILIKE '%rgb%' OR pr.name ILIKE '%gamer%'\n" +
  "         OR pr.description ILIKE '%rgb%' OR pr.description ILIKE '%colorid%'\n" +
  "         OR EXISTS (SELECT 1 FROM unnest(pr.tags) t WHERE t ILIKE '%rgb%' OR t ILIKE '%colorid%')\n" +
  "       ) THEN 6 ELSE 0 END)\n" +
  "    + (CASE WHEN v.wants_rgb AND NOT (\n" +
  "         pr.name ILIKE '%rgb%' OR pr.name ILIKE '%gamer%'\n" +
  "         OR pr.description ILIKE '%rgb%' OR pr.description ILIKE '%colorid%'\n" +
  "         OR EXISTS (SELECT 1 FROM unnest(pr.tags) t WHERE t ILIKE '%rgb%' OR t ILIKE '%colorid%')\n" +
  "       ) THEN -3 ELSE 0 END)\n" +
  "    + (pr.rating * 0.1)\n" +
  "    + (CASE WHEN pr.is_best_seller THEN 0.5 ELSE 0 END) ) AS score\n" +
  "  FROM vis v CROSS JOIN products pr\n" +
  "  WHERE pr.active = TRUE\n" +
  "),\n" +
  "top AS (\n" +
  "  SELECT sid, rationale, confident,\n" +
  "    (SELECT array_agg(s2.id ORDER BY s2.score DESC, s2.id)\n" +
  "     FROM (SELECT id, score FROM scored s3 ORDER BY s3.score DESC LIMIT 3) s2) AS ids\n" +
  "  FROM scored GROUP BY sid, rationale, confident\n" +
  "),\n" +
  "final_msg AS (\n" +
  "  SELECT t.sid, t.ids,\n" +
  "    t.rationale || CASE WHEN t.confident THEN '' ELSE ' Me conta pra qual comodo e o clima que voce quer (aconchegante ou produtivo) que eu refino a recomendacao.' END AS reply\n" +
  "  FROM top t\n" +
  "),\n" +
  "ins AS (\n" +
  "  INSERT INTO chat_messages (session_id, author, type, text, product_recommendations)\n" +
  "  SELECT fm.sid, 'bot',\n" +
  "    CASE WHEN array_length(fm.ids,1) > 0 THEN 'productRecommendation' ELSE 'text' END,\n" +
  "    fm.reply, fm.ids\n" +
  "  FROM final_msg fm\n" +
  "  RETURNING id, author, type, text, product_recommendations, created_at\n" +
  ")\n" +
  "SELECT 200 AS \"statusCode\",\n" +
  "  json_build_object(\n" +
  "    'id', i.id, 'author', i.author, 'type', i.type, 'text', i.text,\n" +
  "    'product_recommendations', to_jsonb(coalesce(i.product_recommendations, ARRAY[]::uuid[])),\n" +
  "    'created_at', to_char(i.created_at AT TIME ZONE 'UTC','YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')\n" +
  "  ) AS body\n" +
  "FROM ins i;";

const webhook = trigger({
  type: 'n8n-nodes-base.webhook',
  version: 2.1,
  config: { name: 'POST /consultant/image', parameters: { httpMethod: 'POST', path: 'consultant/image', responseMode: 'responseNode', options: {} }, position: [0, 0] },
  output: [{ body: {} }],
});

const checkKey = ifElse({
  version: 2.3,
  config: { name: 'Check X-API-Key', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: expr('{{ $json.headers["x-api-key"] }}'), rightValue: 'raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2', operator: { type: 'string', operation: 'equals' } }] }, options: {} }, position: [240, 0] },
});

const auth = node({
  type: 'n8n-nodes-base.postgres',
  version: 2.6,
  config: { name: 'Auth + log image msg', parameters: { operation: 'executeQuery', query: authQuery, options: { queryReplacement: expr('{{ [ ((($json.headers && $json.headers.authorization) ? $json.headers.authorization : "").replace(/^Bearer /i, "") || "__NULL__"), (($json.body && $json.body.session_id) ? $json.body.session_id : "__NULL__"), (($json.body && $json.body.image_path) ? $json.body.image_path : "__NULL__"), (($json.body && $json.body.text) ? $json.body.text : "__NULL__") ] }}') } }, alwaysOutputData: true, position: [480, 0] },
  output: [{ statusCode: 200, session_id: 's', image_url: 'u', user_text: 't' }],
});

const authorized = ifElse({
  version: 2.3,
  config: { name: 'Authorized?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: expr('{{ $json.statusCode }}'), rightValue: 200, operator: { type: 'number', operation: 'equals' } }] }, options: {} }, position: [720, 0] },
});

const vision = node({
  type: 'n8n-nodes-base.httpRequest',
  version: 4.4,
  config: { name: 'ModelScope visao', parameters: { method: 'POST', url: 'https://api-inference.modelscope.ai/v1/chat/completions', sendHeaders: true, specifyHeaders: 'keypair', headerParameters: { parameters: [{ name: 'Authorization', value: MS_TOKEN }] }, sendBody: true, contentType: 'json', specifyBody: 'json', jsonBody: expr(visionBody), options: { response: { response: { neverError: true } } } }, executeOnce: true, alwaysOutputData: true, position: [960, -128] },
  output: [{ choices: [{ message: { content: '{}' } }] }],
});

const recommend = node({
  type: 'n8n-nodes-base.postgres',
  version: 2.6,
  config: { name: 'Recommend + save', parameters: { operation: 'executeQuery', query: recommendQuery, options: { queryReplacement: expr('{{ [ ($node["Auth + log image msg"].json.session_id || "__NULL__"), ($json.choices && $json.choices[0] && $json.choices[0].message && $json.choices[0].message.content ? $json.choices[0].message.content : "__NULL__") ] }}') } }, alwaysOutputData: true, position: [1200, -128] },
  output: [{ statusCode: 200, body: {} }],
});

const respondOk = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond 200 (Bot msg)', parameters: { respondWith: 'json', responseBody: expr('{{ $json.body }}'), options: { responseCode: 200 } }, position: [1440, -128] },
  output: [{}],
});

const respond401Jwt = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond 401 (JWT)', parameters: { respondWith: 'json', responseBody: expr('{{ { "message": "Nao autorizado" } }}'), options: { responseCode: 401 } }, position: [944, 208] },
  output: [{}],
});

const respond401Key = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond 401 (API Key)', parameters: { respondWith: 'json', responseBody: expr('{{ { "message": "Invalid API key" } }}'), options: { responseCode: 401 } }, position: [480, 224] },
  output: [{}],
});

export default workflow('ZPXUabfOyQSxfRVp', 'consultant-image-raitocorp')
  .add(webhook)
  .to(checkKey
    .onTrue(auth.to(authorized
      .onTrue(vision.to(recommend.to(respondOk)))
      .onFalse(respond401Jwt)))
    .onFalse(respond401Key));
