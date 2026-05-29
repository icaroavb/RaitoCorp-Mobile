import { workflow, node, trigger, ifElse, expr } from '@n8n/workflow-sdk';

const SECRET = 'bj6VFq3FcdWYVl4Mv-3_fDSbGesnSfjHdVOq8VoFqfshrZo0W7x3tZPHTztc-3sl';
const MS_TOKEN = 'Bearer ms-ca592d9a-ec9b-4052-ad94-0bb6433aaec4';

const promptCode =
  "const MS_TOKEN='" + MS_TOKEN + "';\n" +
  "function shrink(u){return (typeof u==='string'&&u.includes('/upload/')&&u.includes('res.cloudinary.com'))?u.replace('/upload/','/upload/w_1024,h_1024,c_limit/'):u;}\n" +
  "function buildPrompt(src){\n" +
  "  const temp=src.light_temperature==='cool'?'cool white 6000K':src.light_temperature==='neutral'?'neutral 4000K':'warm 3000K';\n" +
  "  const bright=src.brightness_level==='intense'?'bright high-intensity':src.brightness_level==='soft'?'soft low-intensity':'medium-intensity';\n" +
  "  const cat=(src.category||'').toLowerCase();\n" +
  "  let place;\n" +
  "  if(cat==='strip'){ place='Install this LED strip as accent lighting: run it along the edges of the ceiling, behind furniture, under cabinets or along the headboard of the bed. It is a thin flexible light strip, NOT a ceiling lamp. Do NOT put a panel or fixture on the ceiling center.'; }\n" +
  "  else if(cat==='spot'||cat==='panel'||cat==='plafon'){ place='Install this product recessed into or surface-mounted flat on the ceiling, as a downlight/panel.'; }\n" +
  "  else if(cat==='pendant'||cat==='chandelier'||cat==='lustre'){ place='Hang this pendant/chandelier from the ceiling at an appropriate height, replacing any existing ceiling light.'; }\n" +
  "  else if(cat==='floorlamp'||cat==='piso'){ place='Place this floor lamp standing on the floor in a corner of the room next to furniture.'; }\n" +
  "  else if(cat==='lamp'||cat==='abajur'||cat==='table'){ place='Place this table lamp on a desk, nightstand or shelf in the room.'; }\n" +
  "  else if(cat==='walllamp'||cat==='arandela'||cat==='sconce'){ place='Mount this wall sconce on a wall of the room at mid height.'; }\n" +
  "  else if(cat==='track'||cat==='trilho'){ place='Mount this track lighting bar on the ceiling and aim the spots into the room.'; }\n" +
  "  else { place='Install this lighting product in the most realistic and appropriate position for its type in the room.'; }\n" +
  "  return 'The first image is a photo of a room. The second image shows a specific lighting product. Take that EXACT product from the second image and install it in the room. '+place+' The installed product MUST look identical to the second image: same shape, same material, same color, same design. Turn it on, emitting '+temp+' '+bright+' light that realistically illuminates the room. Keep all furniture, layout, walls, windows and camera perspective exactly unchanged. Photorealistic interior photography.';\n" +
  "}\n" +
  "const src=$node[\"Auth + limite + fontes\"].json;\n" +
  "const prompt=buildPrompt(src);\n" +
  "let tid=null;\n" +
  "try{ const r=await this.helpers.httpRequest({method:'POST',url:'https://api-inference.modelscope.ai/v1/images/generations',headers:{'Authorization':MS_TOKEN,'X-ModelScope-Async-Mode':'true'},body:{model:'Qwen/Qwen-Image-Edit-2509',image_url:[shrink(src.env_url),shrink(src.product_url)],prompt},json:true}); tid=r.task_id||null; }catch(e){ tid=null; }\n" +
  "return [{ json:{ status:'processing', task_id: tid } }];";

const authQuery =
  "CREATE TABLE IF NOT EXISTS preview_usage (\n" +
  "  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n" +
  "  user_id UUID NOT NULL,\n" +
  "  product_id UUID,\n" +
  "  result_url TEXT,\n" +
  "  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n" +
  ");\n" +
  "WITH input AS (\n" +
  "  SELECT nullif($1,'__NULL__')::text AS raw,\n" +
  "         nullif($2,'__NULL__')::text AS sid,\n" +
  "         nullif($3,'__NULL__')::text AS pid,\n" +
  "         nullif($4,'__NULL__')::text AS task_id,\n" +
  "         '" + SECRET + "'::text AS secret\n" +
  "),\n" +
  "parts AS (\n" +
  "  SELECT i.secret, i.sid, i.pid, i.task_id,\n" +
  "    split_part(coalesce(i.raw,''),'.',1) AS h,\n" +
  "    split_part(coalesce(i.raw,''),'.',2) AS p,\n" +
  "    split_part(coalesce(i.raw,''),'.',3) AS sig,\n" +
  "    coalesce(i.raw,'') AS raw\n" +
  "  FROM input i\n" +
  "),\n" +
  "verify AS (\n" +
  "  SELECT pa.p, pa.sid, pa.pid, pa.task_id,\n" +
  "    (pa.raw <> '' AND pa.sig = replace(replace(translate(encode(hmac(pa.h||'.'||pa.p, pa.secret,'sha256'),'base64'),'+/','-_'),'=',''), E'\\n','')) AS sig_ok\n" +
  "  FROM parts pa\n" +
  "),\n" +
  "claims AS (\n" +
  "  SELECT v.sig_ok, v.sid, v.pid, v.task_id,\n" +
  "    CASE WHEN v.sig_ok THEN convert_from(decode(translate(v.p,'-_','+/')||repeat('=',(4-length(v.p)%4)%4),'base64'),'UTF8')::json END AS payload\n" +
  "  FROM verify v\n" +
  "),\n" +
  "final AS (\n" +
  "  SELECT (c.sig_ok AND (c.payload->>'exp')::bigint > extract(epoch from now())::bigint) AS auth_ok,\n" +
  "    (c.payload->>'sub') AS uid, c.sid, c.pid, c.task_id\n" +
  "  FROM claims c\n" +
  "),\n" +
  "usage AS (\n" +
  "  SELECT count(*) AS used_today\n" +
  "  FROM preview_usage pu, final f\n" +
  "  WHERE f.auth_ok AND pu.user_id = f.uid::uuid AND pu.created_at >= date_trunc('day', now() AT TIME ZONE 'UTC')\n" +
  "),\n" +
  "prod AS (\n" +
  "  SELECT pr.image_urls[1] AS product_url, pr.name AS product_name,\n" +
  "    coalesce(pr.light_temperature,'warm') AS light_temperature,\n" +
  "    coalesce(pr.brightness_level,'medium') AS brightness_level,\n" +
  "    coalesce(pr.category,'') AS category\n" +
  "  FROM products pr, final f\n" +
  "  WHERE f.auth_ok AND f.pid IS NOT NULL AND pr.id::text = f.pid AND pr.active = TRUE\n" +
  "),\n" +
  "env AS (\n" +
  "  SELECT m.image_path AS env_url\n" +
  "  FROM chat_messages m, final f\n" +
  "  WHERE f.auth_ok AND m.session_id = f.sid AND m.type = 'image' AND m.author = 'user' AND m.image_path IS NOT NULL\n" +
  "  ORDER BY m.created_at DESC LIMIT 1\n" +
  ")\n" +
  "SELECT\n" +
  "  CASE\n" +
  "    WHEN NOT f.auth_ok THEN 401\n" +
  "    WHEN f.task_id IS NULL AND (SELECT used_today FROM usage) >= 2 THEN 429\n" +
  "    WHEN f.task_id IS NULL AND (SELECT env_url FROM env) IS NULL THEN 422\n" +
  "    WHEN f.task_id IS NULL AND (SELECT product_url FROM prod) IS NULL THEN 404\n" +
  "    ELSE 200\n" +
  "  END AS \"statusCode\",\n" +
  "  f.uid AS user_id, f.sid AS session_id, f.pid AS product_id, f.task_id AS task_id,\n" +
  "  (SELECT product_url FROM prod) AS product_url,\n" +
  "  (SELECT product_name FROM prod) AS product_name,\n" +
  "  (SELECT light_temperature FROM prod) AS light_temperature,\n" +
  "  (SELECT brightness_level FROM prod) AS brightness_level,\n" +
  "  (SELECT category FROM prod) AS category,\n" +
  "  (SELECT env_url FROM env) AS env_url,\n" +
  "  CASE\n" +
  "    WHEN NOT f.auth_ok THEN 'Nao autorizado'\n" +
  "    WHEN f.task_id IS NULL AND (SELECT used_today FROM usage) >= 2 THEN 'Voce ja usou seus 2 previews de hoje. Volte amanha pra testar mais ambientes!'\n" +
  "    WHEN f.task_id IS NULL AND (SELECT env_url FROM env) IS NULL THEN 'Manda primeiro uma foto do seu ambiente aqui no chat, dai eu mostro como o produto fica nele.'\n" +
  "    WHEN f.task_id IS NULL AND (SELECT product_url FROM prod) IS NULL THEN 'Nao encontrei esse produto.'\n" +
  "    ELSE 'ok'\n" +
  "  END AS message\n" +
  "FROM final f;";

const checkCode =
  "const MS_TOKEN='" + MS_TOKEN + "';\n" +
  "const tid=($node[\"POST /consultant/preview\"].json.body||{}).task_id;\n" +
  "let chk=null;\n" +
  "try{ chk=await this.helpers.httpRequest({method:'GET',url:'https://api-inference.modelscope.ai/v1/tasks/'+tid,headers:{'Authorization':MS_TOKEN,'X-ModelScope-Task-Type':'image_generation'},json:true}); }catch(e){ return [{ json:{ status:'processing', task_id: tid } }]; }\n" +
  "const st=chk.task_status;\n" +
  "if(st==='SUCCEED'){ const url=(chk.output_images||[])[0]||null; return [{ json: url?{status:'ready',result_url:url}:{status:'processing',task_id:tid} }]; }\n" +
  "if(st==='FAILED'){ return [{ json:{ status:'failed', task_id: tid } }]; }\n" +
  "return [{ json:{ status:'processing', task_id: tid } }];";

const registerQuery =
  "WITH src AS (\n" +
  "  SELECT nullif($1,'__NULL__')::text AS uid,\n" +
  "         nullif($2,'__NULL__')::text AS sid,\n" +
  "         nullif($3,'__NULL__')::text AS pid,\n" +
  "         nullif($4,'__NULL__')::text AS result_url,\n" +
  "         nullif($5,'__NULL__')::text AS product_name\n" +
  "),\n" +
  "log AS (\n" +
  "  INSERT INTO preview_usage (user_id, product_id, result_url)\n" +
  "  SELECT s.uid::uuid, s.pid::uuid, s.result_url FROM src s WHERE s.result_url IS NOT NULL\n" +
  "  RETURNING id\n" +
  "),\n" +
  "ins AS (\n" +
  "  INSERT INTO chat_messages (session_id, author, type, text, image_path)\n" +
  "  SELECT s.sid, 'bot', 'image',\n" +
  "    'Olha como o ' || coalesce(s.product_name,'produto') || ' ficaria no seu ambiente! Toque para ver maior.',\n" +
  "    s.result_url\n" +
  "  FROM src s WHERE s.result_url IS NOT NULL\n" +
  "  RETURNING id, author, type, text, image_path, product_recommendations, created_at\n" +
  ")\n" +
  "SELECT 200 AS \"statusCode\",\n" +
  "  json_build_object('status','ready','message', json_build_object(\n" +
  "    'id', i.id, 'author', i.author, 'type', i.type, 'text', i.text,\n" +
  "    'image_path', i.image_path,\n" +
  "    'product_recommendations', to_jsonb(coalesce(i.product_recommendations, ARRAY[]::uuid[])),\n" +
  "    'created_at', to_char(i.created_at AT TIME ZONE 'UTC','YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')\n" +
  "  )) AS body\n" +
  "FROM ins i;";

const webhook = trigger({
  type: 'n8n-nodes-base.webhook',
  version: 2.1,
  config: { name: 'POST /consultant/preview', parameters: { httpMethod: 'POST', path: 'consultant/preview', responseMode: 'responseNode', options: {} }, position: [0, 0] },
  output: [{ body: {} }],
});

const checkKey = ifElse({
  version: 2.3,
  config: { name: 'Check X-API-Key', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: expr('{{ $json.headers["x-api-key"] }}'), rightValue: 'raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2', operator: { type: 'string', operation: 'equals' } }] }, options: {} }, position: [240, 0] },
});

const auth = node({
  type: 'n8n-nodes-base.postgres',
  version: 2.6,
  config: { name: 'Auth + limite + fontes', parameters: { operation: 'executeQuery', query: authQuery, options: { queryReplacement: expr('{{ ((($json.headers && $json.headers.authorization) ? $json.headers.authorization : "").replace(/^Bearer /i, "") || "__NULL__") + "," + (($json.body && $json.body.session_id) ? $json.body.session_id : "__NULL__") + "," + (($json.body && $json.body.product_id) ? $json.body.product_id : "__NULL__") + "," + (($json.body && $json.body.task_id) ? $json.body.task_id : "__NULL__") }}') } }, alwaysOutputData: true, position: [496, -80] },
  output: [{ statusCode: 200, user_id: 'u', session_id: 's', product_id: 'p', category: 'strip', env_url: 'e', product_url: 'pu' }],
});

const canProceed = ifElse({
  version: 2.3,
  config: { name: 'Pode prosseguir?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: expr('{{ $json.statusCode }}'), rightValue: 200, operator: { type: 'number', operation: 'equals' } }] }, options: {} }, position: [720, 0] },
});

const hasTask = ifElse({
  version: 2.3,
  config: { name: 'Tem task_id?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'loose', version: 2 }, conditions: [{ leftValue: expr('{{ $node["POST /consultant/preview"].json.body.task_id }}'), rightValue: '', operator: { type: 'string', operation: 'notEmpty', singleValue: true } }] }, options: {} }, position: [960, 0] },
});

const checkMs = node({
  type: 'n8n-nodes-base.code',
  version: 2,
  config: { name: 'Check ModelScope', parameters: { mode: 'runOnceForAllItems', language: 'javaScript', jsCode: checkCode }, alwaysOutputData: true, position: [1200, -160] },
  output: [{ status: 'ready', result_url: 'x' }],
});

const ready = ifElse({
  version: 2.3,
  config: { name: 'Pronto?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'loose', version: 2 }, conditions: [{ leftValue: expr('{{ $json.status }}'), rightValue: 'ready', operator: { type: 'string', operation: 'equals' } }] }, options: {} }, position: [1440, -160] },
});

const upload = node({
  type: 'n8n-nodes-base.httpRequest',
  version: 4.4,
  config: { name: 'Upload Cloudinary', parameters: { method: 'POST', url: 'https://api.cloudinary.com/v1_1/dvt0gyhlr/image/upload', sendBody: true, contentType: 'multipart-form-data', bodyParameters: { parameters: [{ name: 'upload_preset', value: 'raitocorp-mobile' }, { name: 'file', value: expr('{{ $json.result_url }}') }] }, options: { response: { response: { neverError: true } } } }, executeOnce: true, alwaysOutputData: true, position: [1680, -256] },
  output: [{ secure_url: 'x', bytes: 50000 }],
});

const validImg = ifElse({
  version: 2.3,
  config: { name: 'Imagem valida?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'loose', version: 2 }, conditions: [{ leftValue: expr('{{ $json.secure_url }}'), rightValue: '', operator: { type: 'string', operation: 'notEmpty', singleValue: true } }, { leftValue: expr('{{ $json.bytes }}'), rightValue: 20000, operator: { type: 'number', operation: 'gte' } }] }, options: {} }, position: [1840, -256] },
});

const register = node({
  type: 'n8n-nodes-base.postgres',
  version: 2.6,
  config: { name: 'Registra uso + msg', parameters: { operation: 'executeQuery', query: registerQuery, options: { queryReplacement: expr('{{ ($node["Auth + limite + fontes"].json.user_id || "__NULL__") + "," + ($node["Auth + limite + fontes"].json.session_id || "__NULL__") + "," + ($node["Auth + limite + fontes"].json.product_id || "__NULL__") + "," + (($node["Upload Cloudinary"].json.secure_url) ? $node["Upload Cloudinary"].json.secure_url : "__NULL__") + "," + ($node["Auth + limite + fontes"].json.product_name || "__NULL__") }}') } }, alwaysOutputData: true, position: [2080, -360] },
  output: [{ statusCode: 200, body: {} }],
});

const respondReady = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond ready', parameters: { respondWith: 'json', responseBody: expr('{{ $json.body }}'), options: { responseCode: 200 } }, position: [2320, -360] },
  output: [{}],
});

const failed = ifElse({
  version: 2.3,
  config: { name: 'Falhou?', parameters: { conditions: { combinator: 'and', options: { caseSensitive: true, typeValidation: 'loose', version: 2 }, conditions: [{ leftValue: expr('{{ $json.status }}'), rightValue: 'failed', operator: { type: 'string', operation: 'equals' } }] }, options: {} }, position: [1664, 16] },
});

const resubmit = node({
  type: 'n8n-nodes-base.code',
  version: 2,
  config: { name: 'Re-submit', parameters: { mode: 'runOnceForAllItems', language: 'javaScript', jsCode: promptCode }, alwaysOutputData: true, position: [1968, -16] },
  output: [{ status: 'processing', task_id: 't' }],
});

const submit = node({
  type: 'n8n-nodes-base.code',
  version: 2,
  config: { name: 'Submit ModelScope', parameters: { mode: 'runOnceForAllItems', language: 'javaScript', jsCode: promptCode }, alwaysOutputData: true, position: [1200, 160] },
  output: [{ status: 'processing', task_id: 't' }],
});

const respondProcessing = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond processing', parameters: { respondWith: 'json', responseBody: expr('{{ { "status": "processing", "task_id": $json.task_id } }}'), options: { responseCode: 200 } }, position: [2160, 160] },
  output: [{}],
});

const respondBlocked = node({
  type: 'n8n-nodes-base.respondToWebhook',
  version: 1.5,
  config: { name: 'Respond bloqueado', parameters: { respondWith: 'json', responseBody: expr('{{ { "message": $json.message } }}'), options: { responseCode: expr('{{ $json.statusCode }}') } }, position: [768, 464] },
  output: [{}],
});

export default workflow('lX0V2tGrBSum9WvO', 'consultant-preview-raitocorp')
  .add(webhook)
  .to(checkKey
    .onTrue(auth.to(canProceed
      .onTrue(hasTask
        .onTrue(checkMs.to(ready
          .onTrue(upload.to(validImg
            .onTrue(register.to(respondReady))
            .onFalse(resubmit.to(respondProcessing))))
          .onFalse(failed
            .onTrue(resubmit.to(respondProcessing))
            .onFalse(respondProcessing))))
        .onFalse(submit.to(respondProcessing)))
      .onFalse(respondBlocked)))
    .onFalse(respondBlocked));
