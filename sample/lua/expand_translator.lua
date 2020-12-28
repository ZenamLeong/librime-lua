

--[[
in cangjie5.schema.yaml

schema:
  schema_id: cangjie5
engine:
  translators:
    - lua_translator@expand_translator

expand_translator:
	wildcard: "*"

// you must add wildcard to speller, otherwise the Rime won't take it as normal input;
speller:
  alphabet: zyxwvutsrqponmlkjihgfedcba*
]]

local thisEnv = nil

local function memoryCallback(commit)
	-- because librime-lua currently using simple Candidate, Cannot callback this function.
	print("following committed!")
	for i,dictentry in ipairs(commit:get())
	do
		print(dictentry.text .. " " .. dictentry.weight .. " " .. dictentry.comment .. "")
		thisEnv.mem:updateUserdict(dictentry,0,"") -- do nothing to userdict
		-- thisEnv.mem:updateUserdict(dictentry,1,"") -- update entry to userdict
		-- thisEnv.mem:updateUserdict(dictentry,1,"") -- delete entry to userdict
	end
end
local function init(env)
   env.mem = Memory(env.engine,env.engine.schema)
   env.mem:memorize(memoryCallback)
   -- or use
	 -- env.mem = CustomMemory(env.engine,"cangjie5.schema","translator")
   config = env.engine.schema.config
   namespace = 'expand_translator'
   env.wildcard = config:get_string(namespace .. '/wildcard')
   -- or try get config like this
   -- schema = Schema("cangjie5") -- schema_id
   -- config = schema.config
   thisEnv = env
   print("expand_translator Initilized!")
end


local function translate(inp,seg,env)
	if string.match(inp,env.wildcard) then
		local tail = string.match(inp,  '[^'.. env.wildcard .. ']+$') or ''
		inp = string.match(inp, '^[^' ..env.wildcard .. ']+')
		env.mem:dictLookup(inp,true)  -- expand_search
		for dictentry in env.mem:iter_dict()
		do
			local codetail = string.match(dictentry.comment,tail .. '$') or ''
			if tail ~= nil and codetail == tail then	
				local code = env.mem:decode(dictentry.code)
				codeComment = table.concat(code, ",")
				local ph = Phrase(env.mem,"expand_translator", seg.start, seg._end, dictentry)
				ph.comment = codeComment
				yield(ph:toCandidate())
				-- you can also use Candidate Simply, but it cannot be recognized by memorize, memorize callback won't be called
				-- yield(Candidate("type",seg.start,seg.end,dictentry.text, codeComment	))
			end
		end
	end
end	

return {init = init, func = translate}	