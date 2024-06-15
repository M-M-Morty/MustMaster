local string = string
local tonumber = tonumber
local setmetatable = setmetatable
local error = error
local ipairs = ipairs
local io = io
local table = table
local math = math
local assert = assert
local tostring = tostring
local type = type
local insert_tab = table.insert

local function meta(name, t)
   t = t or {}
   t.__name  = name
   t.__index = t
   return t
end

local function default(t, k, def)
   local v = t[k]
   if not v then
      v = def or {}
      t[k] = v
   end
   return v
end

local Lexer = meta "Lexer" do

local escape = {
   a = "\a", b = "\b", f = "\f", n = "\n",
   r = "\r", t = "\t", v = "\v"
}

local function tohex(x) return string.byte(tonumber(x, 16)) end
local function todec(x) return string.byte(tonumber(x, 10)) end
local function toesc(x) return escape[x] or x end

function Lexer.new(name, src)
   local self = {
      name = name,
      src = src,
      pos = 1
   }
   return setmetatable(self, Lexer)
end

function Lexer:__call(patt, pos)
   return self.src:match(patt, pos or self.pos)
end

function Lexer:test(patt)
   self:whitespace()
   local pos = self('^'..patt..'%s*()')
   if not pos then return false end
   self.pos = pos
   return true
end

function Lexer:expected(patt, name)
   if not self:test(patt) then
      return self:error((name or ("'"..patt.."'")).." expected")
   end
   return self
end

function Lexer:pos2loc(pos)
   local linenr = 1
   pos = pos or self.pos
   for start, stop in self.src:gmatch "()[^\n]*()\n?" do
      if start <= pos and pos <= stop then
         return linenr, pos - start + 1
      end
      linenr = linenr + 1
   end
end

function Lexer:error(fmt, ...)
   local ln, co = self:pos2loc()
   return error(("%s:%d:%d: "..fmt):format(self.name, ln, co, ...))
end

function Lexer:opterror(opt, msg)
   if not opt then return self:error(msg) end
   return nil
end

function Lexer:whitespace()
   local pos, c = self "^%s*()(%/?)"
   self.pos = pos
   if c == '' then return self end
   return self:comment()
end

function Lexer:comment()
   local pos = self "^%/%/[^\n]*\n?()"
   if not pos then
      if self "^%/%*" then
         pos = self "^%/%*.-%*%/()"
         if not pos then
            self:error "unfinished comment"
         end
      end
   end
   if not pos then return self end
   self.pos = pos
   return self:whitespace()
end

function Lexer:line_end(opt)
   self:whitespace()
   local pos = self '^[%s;]*%s*()'
   if not pos then
      return self:opterror(opt, "';' expected")
   end
   self.pos = pos
   return pos
end

function Lexer:eof()
   self:whitespace()
   return self.pos > #self.src
end

function Lexer:keyword(kw, opt)
   self:whitespace()
   local ident, pos = self "^([%a_][%w_]*)%s*()"
   if not ident or ident ~= kw then
      return self:opterror(opt, "''"..kw..'" expected')
   end
   self.pos = pos
   return kw
end

function Lexer:ident(name, opt)
   self:whitespace()
   local b, ident, pos = self "^()([%a_][%w_]*)%s*()"
   if not ident then
      return self:opterror(opt, (name or 'name')..' expected')
   end
   self.pos = pos
   return ident, b
end

function Lexer:full_ident(name, opt)
   self:whitespace()
   local b, ident, pos = self "^()([%a_][%w_.]*)%s*()"
   if not ident or ident:match "%.%.+" then
      return self:opterror(opt, (name or 'name')..' expected')
   end
   self.pos = pos
   return ident, b
end

function Lexer:integer(opt)
   self:whitespace()
   local ns, oct, hex, s, pos =
      self "^([+-]?)(0?)([xX]?)([0-9a-fA-F]+)%s*()"
   local n
   if oct == '0' and hex == '' then
      n = tonumber(s, 8)
   elseif oct == '' and hex == '' then
      n = tonumber(s, 10)
   elseif oct == '0' and hex ~= '' then
      n = tonumber(s, 16)
   end
   if not n then
      return self:opterror(opt, 'integer expected')
   end
   self.pos = pos
   return ns == '-' and -n or n
end

function Lexer:number(opt)
   self:whitespace()
   if self:test "nan%f[%A]" then
      return 0.0/0.0
   elseif self:test "inf%f[%A]" then
      return 1.0/0.0
   end
   local ns, d1, s, d2, s2, pos = self "^([+-]?)(%.?)([0-9]+)(%.?)([0-9]*)()"
   if not ns then
      return self:opterror(opt, 'floating-point number expected')
   end
   local es, pos2 = self("(^[eE][+-]?[0-9]+)%s*()", pos)
   if d1 == "." and d2 == "." then
      return self:error "malformed floating-point number"
   end
   self.pos = pos2 or pos
   local n = tonumber(d1..s..d2..s2..(es or ""))
   return ns == '-' and -n or n
end

function Lexer:quote(opt)
   self:whitespace()
   local q, start = self '^(["\'])()'
   if not start then
      return self:opterror(opt, 'string expected')
   end
   self.pos = start
   local patt = '()(\\?'..q..')%s*()'
   while true do
      local stop, s, pos = self(patt)
      if not stop then
         self.pos = start-1
         return self:error "unfinished string"
      end
      self.pos = pos
      if s == q then
         return self.src:sub(start, stop-1)
                        :gsub("\\x(%x+)", tohex)
                        :gsub("\\(%d+)", todec)
                        :gsub("\\(.)", toesc)
      end
   end
end

function Lexer:structure(opt)
   self:whitespace()
   if not self:test "{" then
      return self:opterror(opt, 'opening curly brace expected')
   end
   local t = {}
   while not self:test "}" do
      local pos, name, npos = self "^%s*()(%b[])()"
      if not pos then
         name = self:full_ident "field name"
      else
         self.pos = npos
      end
      self:test ":"
      local value = self:constant()
      self:test ","
      self:line_end "opt"
      t[name] = value
   end
   return t
end

function Lexer:array(opt)
   self:whitespace()
   if not self:test "%[" then
      return self:opterror(opt, 'opening square bracket expected')
   end
   local t = {}
   while not self:test "]" do
      local value = self:constant()
      self:test ","
      t[#t + 1] = value
   end
   return t
end

function Lexer:constant(opt)
   local c = self:full_ident('constant', 'opt') or
             self:number('opt') or
             self:quote('opt') or
             self:structure('opt') or
             self:array('opt')
   if not c and not opt then
      return self:error "constant expected"
   end
   return c
end

function Lexer:option_name()
   local ident
   if self:test "%(" then
      ident = self:full_ident "option name"
      self:expected "%)"
   else
      ident = self:ident "option name"
   end
   while self:test "%." do
      ident = ident .. "." .. self:ident()
   end
   return ident
end

function Lexer:type_name()
   if self:test "%." then
      local id, pos = self:full_ident "type name"
      return "."..id, pos
   else
      return self:full_ident "type name"
   end
end

end

local Parser = meta "Parser" do
Parser.typemap = {}
Parser.extendeemap = {}
Parser.loaded  = {}
Parser.paths   = { "", "." }

function Parser.new()
   local self = {}
   self.typemap = {}
   self.extendeemap = {}
   self.loaded  = {}
   self.paths   = { "", "." }
   return setmetatable(self, Parser)
end

function Parser:reset()
   self.typemap = {}
   self.extendeemap = {}
   self.loaded  = {}
   return self
end

function Parser:error(msg)
   return self.lex:error(msg)
end

function Parser:addpath(path)
   insert_tab(self.paths, path)
end

--HiGame Begin, load from pak use Unreal file API
local function _ReadFileToString(FileName)
   local File = UE.File()
   if not File:Open(FileName, "r") then
      return ""
   end
   local Content = File:Read("a")
   File:Close()
   return Content
end
--HiGame End

function Parser:parsefile(name)
   local info = self.loaded[name]
   if info then return info end
   local errors = {}
   for _, path in ipairs(self.paths) do
      local fn = path ~= "" and path.."/"..name or name
      --[[
      local fh, err = io.open(fn)
      if fh then
         local content = fh:read "*a"
         info = self:parse(content, name)
         fh:close()
         return info
      end
      --]]
      
      --HiGame Begin, load from pak use Unreal file API
      local content = _ReadFileToString(fn)
      if #content > 0 then
         info = self:parse(content, name)
         return info
      end
      --HiGame End

      insert_tab(errors, err or fn..": ".."unknown error")
   end
   local import_fallback = self.unknown_import
   if import_fallback == true then
      info = import_fallback
   elseif import_fallback then
      info = import_fallback(self, name)
   end
   if not info then
      error("module load error: "..name.."\n\t"..table.concat(errors, "\n\t"))
   end
   return info
end

-- parser

local labels = { optional = 1; required = 2; repeated = 3 }

local key_types = {
   int32    = 5;  int64    = 3;  uint32   = 13;
   uint64   = 4;  sint32   = 17; sint64   = 18;
   fixed32  = 7;  fixed64  = 6;  sfixed32 = 15;
   sfixed64 = 16; bool     = 8;  string   = 9;
}

local com_types = {
   group    = 10; message  = 11; enum     = 14;
}

local types = {
   double   = 1;  float    = 2;  int32    = 5;
   int64    = 3;  uint32   = 13; uint64   = 4;
   sint32   = 17; sint64   = 18; fixed32  = 7;
   fixed64  = 6;  sfixed32 = 15; sfixed64 = 16;
   bool     = 8;  string   = 9;  bytes    = 12;
   group    = 10; message  = 11; enum     = 14;
}

local function register_item(self, lex, typ, tname, value)
   if not tname:match "%."then
      tname = self.prefix..tname
   end
   local map = self[typ.."map"]
   if map[tname] then
      return lex:error("%s %s already defined", typ, tname)
   end
   map[tname] = value
end

local function register_type(self, lex, tname, typ)
   register_item(self, lex, "type", tname, typ)
end

local function register_extendee(self, lex, tname, typ)
   register_item(self, lex, "extendee", tname, typ)
end

local function type_info(lex, tname)
   local tenum = types[tname]
   if com_types[tname] then
      return lex:error("invalid type name: "..tname)
   elseif tenum then
      tname = nil
   end
   return tenum, tname
end

local function map_info(lex)
   local keyt = lex:ident "key type"
   if not key_types[keyt] then
      return lex:error("invalid key type: "..keyt)
   end
   local valt = lex:expected "," :type_name()
   local name = lex:expected ">" :ident()
   local ident = name:gsub("^%a", string.upper)
                     :gsub("_(%a)", string.upper).."Entry"
   local kt, ktn = type_info(lex, keyt)
   local vt, vtn = type_info(lex, valt)
   return name, types.message, ident, {
      name = ident,
      field = {
         {
            name      = "key",
            number    = 1;
            label     = labels.optional,
            type      = kt,
            type_name = ktn
         },
         {
            name      = "value",
            number    = 2;
            label     = labels.optional,
            type      = vt,
            type_name = vtn
         },
      },
      options = { map_entry = true }
   }
end

local function inline_option(lex, info)
   if lex:test "%[" then
      info = info or {}
      while true do
         local name  = lex:option_name()
         local value = lex:expected '=' :constant()
         info[name] = value
         if lex:test "%]" then
            return info
         end
         lex:expected ','
      end
   end
end

local function field(self, lex, ident)
   local name, typ, type_name, map_entry
   if ident == "map" and lex:test "%<" then
      name, typ, type_name, map_entry = map_info(lex)
      self.locmap[map_entry.field[1]] = lex.pos
      self.locmap[map_entry.field[2]] = lex.pos
      register_type(self, lex, type_name, types.message)
   else
      typ, type_name = type_info(lex, ident)
      name = lex:ident()
   end
   local info = {
      name      = name,
      number    = lex:expected "=":integer(),
      label     = ident == "map" and labels.repeated or labels.optional,
      type      = typ,
      type_name = type_name
   }
   local options = inline_option(lex)
   if options then
      info.default_value, options.default = tostring(options.default), nil
      info.json_name, options.json_name = options.json_name, nil
      if options.packed and options.packed == "false" then
         options.packed = false
      end
      info.options = options
   end
   if info.number <= 0 then
      lex:error("invalid tag number: "..info.number)
   end
   return info, map_entry
end

local function label_field(self, lex, ident, parent)
   local label = labels[ident]
   local info, map_entry
   if not label then
      if self.syntax == "proto2" and ident ~= "map" then
         return lex:error("proto2 disallow missing label")
      end
      return field(self, lex, ident)
   end
   local proto3_optional = label == labels.optional and self.syntax == "proto3"
   if proto3_optional and not (self.proto3_optional and parent) then
      return lex:error("proto3 disallow 'optional' label")
   end
   info, map_entry = field(self, lex, lex:type_name())
   if proto3_optional then
      local ot = default(parent, "oneof_decl")
      info.oneof_index = #ot
      ot[#ot+1] = { name = "optional_" .. info.name }
   else
      info.label = label
   end
   return info, map_entry
end

local toplevel = {} do

function toplevel:package(lex, info)
   local package = lex:full_ident 'package name'
   lex:line_end()
   info.package = package
   self.prefix = "."..package.."."
   return self
end

function toplevel:import(lex, info)
   local mode = lex:ident('"weak" or "public"', 'opt') or "public"
   if mode ~= 'weak' and mode ~= 'public' then
      return lex:error '"weak or "public" expected'
   end
   local name = lex:quote()
   lex:line_end()
   local result = self:parsefile(name)
   if self.on_import then
      self.on_import(result)
   end
   local dep = default(info, 'dependency')
   local index = #dep
   dep[index+1] = name
   if mode == "public" then
      local it = default(info, 'public_dependency')
      insert_tab(it, index)
   else
      local it = default(info, 'weak_dependency')
      insert_tab(it, index)
   end
end

local msgbody = {} do

function msgbody:message(lex, info)
   local nested_type = default(info, 'nested_type')
   insert_tab(nested_type, toplevel.message(self, lex))
   return self
end

function msgbody:enum(lex, info)
   local nested_type = default(info, 'enum_type')
   insert_tab(nested_type, toplevel.enum(self, lex))
   return self
end

function msgbody:extend(lex, info)
   local extension = default(info, 'extension')
   local nested_type = default(info, 'nested_type')
   local ft, mt = toplevel.extend(self, lex, {})
   for _, v in ipairs(ft) do
      insert_tab(extension, v)
   end
   for _, v in ipairs(mt) do
      insert_tab(nested_type, v)
   end
   return self
end

function msgbody:extensions(lex, info)
   local rt = default(info, 'extension_range')
   local idx = #rt
   repeat
      local start = lex:integer "field number range"
      local stop = math.floor(2^29)
      if lex:keyword('to', 'opt') then
         if not lex:keyword('max', 'opt') then
            stop = lex:integer "field number range end or 'max'"
         end
         insert_tab(rt, { start = start, ['end'] = stop })
      else
         insert_tab(rt, { start = start, ['end'] = start })
      end
   until not lex:test ','
   rt[idx+1].options = inline_option(lex)
   lex:line_end()
   return self
end

function msgbody:reserved(lex, info)
   lex:whitespace()
   if not lex '^%d' then
      local rt = default(info, 'reserved_name')
      repeat
         insert_tab(rt, (lex:quote()))
      until not lex:test ','
   else
      local rt = default(info, 'reserved_range')
      local first = true
      repeat
         local start = lex:integer(first and 'field name or number range'
                                    or 'field number range')
         if lex:keyword('to', 'opt') then
            if lex:keyword('max', 'opt') then
               insert_tab(rt, { start = start, ['end'] = 2^29-1 })
            else
               local stop = lex:integer 'field number range end'
               insert_tab(rt, { start = start, ['end'] = stop })
            end
         else
            insert_tab(rt, { start = start, ['end'] = start })
         end
         first = false
      until not lex:test ','
   end
   lex:line_end()
   return self
end

function msgbody:oneof(lex, info)
   local fs = default(info, "field")
   local ts = default(info, "nested_type")
   local ot = default(info, "oneof_decl")
   local index = #ot + 1
   local oneof = { name = lex:ident() }
   lex:expected "{"
   while not lex:test "}" do
      local ident = lex:type_name()
      if ident == "option" then
         toplevel.option(self, lex, oneof)
      else
         local f, t = field(self, lex, ident)
         self.locmap[f] = lex.pos
         if t then insert_tab(ts, t) end
         f.oneof_index = index - 1
         insert_tab(fs, f)
      end
      lex:line_end 'opt'
   end
   ot[index] = oneof
end

function msgbody:option(lex, info)
   toplevel.option(self, lex, info)
end

end

function toplevel:message(lex, info)
   local name = lex:ident 'message name'
   local typ = { name = name }
   register_type(self, lex, name, types.message)
   local prefix = self.prefix
   self.prefix = prefix..name.."."
   lex:expected "{"
   while not lex:test "}" do
      local ident, pos = lex:type_name()
      local body_parser = msgbody[ident]
      if body_parser then
         body_parser(self, lex, typ)
      else
         local fs = default(typ, 'field')
         local f, t = label_field(self, lex, ident, typ)
         self.locmap[f] = pos
         insert_tab(fs, f)
         if t then
            local ts = default(typ, 'nested_type')
            insert_tab(ts, t)
         end
      end
      lex:line_end 'opt'
   end
   lex:line_end 'opt'
   if info then
      info = default(info, 'message_type')
      insert_tab(info, typ)
   end
   self.prefix = prefix
   return typ
end

function toplevel:enum(lex, info)
   local name, pos = lex:ident 'enum name'
   local enum = { name = name }
   self.locmap[enum] = pos
   register_type(self, lex, name, types.enum)
   lex:expected "{"
   while not lex:test "}" do
      local ident, pos = lex:ident 'enum constant name'
      if ident == 'option' then
         toplevel.option(self, lex, enum)
      elseif ident == 'reserved' then
         msgbody.reserved(self, lex, enum)
      else
         local values  = default(enum, 'value')
         local number  = lex:expected '=' :integer()
         local value = {
            name    = ident,
            number  = number,
            options = inline_option(lex)
         }
         self.locmap[value] = pos
         insert_tab(values, value)
      end
      lex:line_end 'opt'
   end
   lex:line_end 'opt'
   if info then
      info = default(info, 'enum_type')
      insert_tab(info, enum)
   end
   return enum
end

function toplevel:option(lex, info)
   local ident = lex:option_name()
   lex:expected "="
   local value = lex:constant()
   lex:line_end()
   local options = info and default(info, 'options') or {}
   local exist_values = options[ident]
   if exist_values ~= nil then
       if type(exist_values) == "table" then
           insert_tab(exist_values, value)
       else
           options[ident] = {exist_values, value}
       end
   else
      if ident == "tcaplusservice.tcaplus_index" then
         options[ident] = {value}
      else
         options[ident] = value
      end

   end
   return options, self
end

function toplevel:extend(lex, info)
   local name = lex:type_name()
   local ft = info and default(info, 'extension') or {}
   local mt = info and default(info, 'message_type') or {}
   lex:expected "{"
   while not lex:test "}" do
      local ident, pos = lex:type_name()
      local f, t = label_field(self, lex, ident)
      self.locmap[f] = pos
      f.extendee = name
      register_extendee(self, lex, f.name, f)
      insert_tab(ft, f)
      insert_tab(mt, t)
      lex:line_end 'opt'
   end
   return ft, mt
end

local svr_body = {} do

function svr_body:rpc(lex, info)
   local name, pos = lex:ident "rpc name"
   local rpc = { name = name }
   self.locmap[rpc] = pos
   local _, tn
   lex:expected "%("
   rpc.client_streaming = lex:keyword("stream", "opt")
   _, tn = type_info(lex, lex:type_name())
   if not tn then return lex:error "rpc input type must by message" end
   rpc.input_type = tn
   lex:expected "%)" :expected "returns" :expected "%("
   rpc.server_streaming = lex:keyword("stream", "opt")
   _, tn = type_info(lex, lex:type_name())
   if not tn then return lex:error "rpc output type must by message" end
   rpc.output_type = tn
   lex:expected "%)"
   if lex:test "{" then
      while not lex:test "}" do
         lex:line_end "opt"
         lex:keyword "option"
         toplevel.option(self, lex, rpc)
      end
   end
   lex:line_end "opt"
   local t = default(info, "method")
   insert_tab(t, rpc)
end

function svr_body:option(lex, info)
   return toplevel.option(self, lex, info)
end

function svr_body.stream(_, lex)
   lex:error "stream not implement yet"
end

end

function toplevel:service(lex, info)
   local name, pos = lex:ident 'service name'
   local svr = { name = name }
   self.locmap[svr] = pos
   lex:expected "{"
   while not lex:test "}" do
      local ident = lex:type_name()
      local body_parser = svr_body[ident]
      if body_parser then
         body_parser(self, lex, svr)
      else
         return lex:error "expected 'rpc' or 'option' in service body"
      end
      lex:line_end 'opt'
   end
   lex:line_end 'opt'
   if info then
      info = default(info, 'service')
      insert_tab(info, svr)
   end
   return svr
end

end

local function make_context(self, lex)
   local ctx = {
      syntax  = "proto2";
      locmap  = {};
      prefix  = ".";
      lex     = lex;
   }
   ctx.loaded  = self.loaded
   ctx.typemap = self.typemap
   ctx.extendeemap = self.extendeemap
   ctx.paths   = self.paths
   ctx.proto3_optional =
      self.proto3_optional or self.experimental_allow_proto3_optional
   ctx.unknown_type = self.unknown_type
   ctx.unknown_import = self.unknown_import
   ctx.on_import = self.on_import

   return setmetatable(ctx, Parser)
end

function Parser:parse(src, name)
   local loaded = self.loaded[name]
   if loaded then
      if loaded == true then
         error("loop loaded: "..name)
      end
      return loaded
   end

   name = name or "<input>"
   self.loaded[name] = true
   local lex = Lexer.new(name, src)
   local ctx = make_context(self, lex)
   local info = { name = lex.name, syntax = ctx.syntax }

   local syntax = lex:keyword('syntax', 'opt')
   if syntax then
      info.syntax = lex:expected '=' :quote()
      ctx.syntax  = info.syntax
      lex:line_end()
   end

   while not lex:eof() do
      local ident = lex:ident()
      local top_parser = toplevel[ident]
      if top_parser then
         top_parser(ctx, lex, info)
      else
         lex:error("unknown keyword '"..ident.."'")
      end
      lex:line_end "opt"
   end
   self.loaded[name] = name ~= "<input>" and info or nil
   return ctx:resolve(lex, info)
end

-- resolver

local function empty() end

local function iter(t, k)
   local v = t[k]
   if v then return ipairs(v) end
   return empty
end

local function check_dup(self, lex, typ, map, k, v)
   local old = map[v[k]]
   if old then
      local ln, co = lex:pos2loc(self.locmap[old])
      lex:error("%s '%s' exists, previous at %d:%d",
                typ, v[k], ln, co)
   end
   map[v[k]] = v
end

local function check_type(self, lex, tname)
   if tname:match "^%." then
      local t = self.typemap[tname]
      if not t then
         return lex:error("unknown type '%s'", tname)
      end
      return t, tname
   end
   local prefix = self.prefix
   for i = #prefix+1, 1, -1 do
      local op = prefix[i]
      prefix[i] = tname
      local tn = table.concat(prefix, ".", 1, i)
      prefix[i] = op
      local t = self.typemap[tn]
      if t then return t, tn end
   end
   local tn, t
   local type_fallback = self.unknown_type
   if type_fallback then
      if type_fallback == true then
         tn = true
      elseif type(type_fallback) == 'string' then
         tn = tname:match(type_fallback) and true
      else
         tn = type_fallback(self, tname)
      end
   end
   if tn then
      t = types[t or "message"]
      if tn == true then tn = "."..tname end
      return t, tn
   end
   return lex:error("unknown type '%s'", tname)
end

local function check_options(self, lex, info)
   local options = info.options
   if options == nil then
      return
   end
   for k, v in pairs(options) do
      local ot = self.extendeemap["."..k]
      if not ot then
         lex:error("unknown option '%s'", k)
      end
      if ot.label == labels.repeated and type(v) ~= "table" then
         options[k] = {v}
      end
   end
end

local function check_field(self, lex, info)
   if info.extendee then
      local t, tn = check_type(self, lex, info.extendee)
      if t ~= types.message then
         lex:error("message type expected in extension")
      end
      info.extendee = tn
   end
   if info.type_name then
      local t, tn = check_type(self, lex, info.type_name)
      info.type      = t
      info.type_name = tn
   end
end

local function check_enum(self, lex, info)
   local names, numbers = {}, {}
   for _, v in iter(info, 'value') do
      lex.pos = assert(self.locmap[v])
      check_dup(self, lex, 'enum name', names, 'name', v)
      if not (info.options and info.options.allow_alias) then
          check_dup(self, lex, 'enum number', numbers, 'number', v)
      end
   end
end

local function check_message(self, lex, info)
   insert_tab(self.prefix, info.name)
   local names, numbers = {}, {}
   for _, v in iter(info, 'field') do
      lex.pos = assert(self.locmap[v])
      check_dup(self, lex, 'field name', names, 'name', v)
      check_dup(self, lex, 'field number', numbers, 'number', v)
      check_field(self, lex, v)
   end
   for _, v in iter(info, 'nested_type') do
      check_message(self, lex, v)
   end
   for _, v in iter(info, 'extension') do
      lex.pos = assert(self.locmap[v])
      check_field(self, lex, v)
   end
   self.prefix[#self.prefix] = nil
end

local function check_service(self, lex, info)
   local names = {}
   for _, v in iter(info, 'method') do
      lex.pos = self.locmap[v]
      check_dup(self, lex, 'rpc name', names, 'name', v)
      local t, tn = check_type(self, lex, v.input_type)
      v.input_type = tn
      if t ~= types.message then
         lex:error "message type expected in parameter"
      end
      t, tn = check_type(self, lex, v.output_type)
      v.output_type = tn
      if t ~= types.message then
         lex:error "message type expected in return"
      end
      check_options(self, lex, v)
   end
   check_options(self, lex, info)
end

function Parser:resolve(lex, info)
   self.prefix = { "", info.package }
   for _, v in iter(info, 'message_type') do
      check_message(self, lex, v)
   end
   for _, v in iter(info, 'enum_type') do
      check_enum(self, lex, v)
   end
   for _, v in iter(info, 'service') do
      check_service(self, lex, v)
   end
   for _, v in iter(info, 'extension') do
      lex.pos = assert(self.locmap[v])
      check_field(self, lex, v)
   end
   self.prefix = nil
   return info
end

end

local has_pb, pb = pcall(require, "pb") do
if has_pb then
   local descriptor_pb =
   "\10\192.\10\16descriptor.proto\18\15google.protobuf\"G\10\17FileDescript"..
   "orSet\0182\10\4file\24\1 \3(\0112$.google.protobuf.FileDescriptorProto\""..
   "\219\3\10\19FileDescriptorProto\18\12\10\4name\24\1 \1(\9\18\15\10\7pack"..
   "age\24\2 \1(\9\18\18\10\10dependency\24\3 \3(\9\18\25\10\17public_depend"..
   "ency\24\10 \3(\5\18\23\10\15weak_dependency\24\11 \3(\5\0186\10\12messag"..
   "e_type\24\4 \3(\0112 .google.protobuf.DescriptorProto\0187\10\9enum_type"..
   "\24\5 \3(\0112$.google.protobuf.EnumDescriptorProto\0188\10\7service\24\6"..
   " \3(\0112'.google.protobuf.ServiceDescriptorProto\0188\10\9extension\24\7"..
   " \3(\0112%.google.protobuf.FieldDescriptorProto\18-\10\7options\24\8 \1("..
   "\0112\28.google.protobuf.FileOptions\0189\10\16source_code_info\24\9 \1("..
   "\0112\31.google.protobuf.SourceCodeInfo\18\14\10\6syntax\24\12 \1(\9\"\169"..
   "\5\10\15DescriptorProto\18\12\10\4name\24\1 \1(\9\0184\10\5field\24\2 \3"..
   "(\0112%.google.protobuf.FieldDescriptorProto\0188\10\9extension\24\6 \3("..
   "\0112%.google.protobuf.FieldDescriptorProto\0185\10\11nested_type\24\3 \3"..
   "(\0112 .google.protobuf.DescriptorProto\0187\10\9enum_type\24\4 \3(\0112"..
   "$.google.protobuf.EnumDescriptorProto\18H\10\15extension_range\24\5 \3(\011"..
   "2/.google.protobuf.DescriptorProto.ExtensionRange\0189\10\10oneof_decl\24"..
   "\8 \3(\0112%.google.protobuf.OneofDescriptorProto\0180\10\7options\24\7 "..
   "\1(\0112\31.google.protobuf.MessageOptions\18F\10\14reserved_range\24\9 "..
   "\3(\0112..google.protobuf.DescriptorProto.ReservedRange\18\21\10\13reser"..
   "ved_name\24\10 \3(\9\26e\10\14ExtensionRange\18\13\10\5start\24\1 \1(\5\18"..
   "\11\10\3end\24\2 \1(\5\0187\10\7options\24\3 \1(\0112&.google.protobuf.E"..
   "xtensionRangeOptions\26+\10\13ReservedRange\18\13\10\5start\24\1 \1(\5\18"..
   "\11\10\3end\24\2 \1(\5\"g\10\21ExtensionRangeOptions\18C\10\20uninterpre"..
   "ted_option\24\231\7 \3(\0112$.google.protobuf.UninterpretedOption*\9\8\232"..
   "\7\16\128\128\128\128\2\"\188\5\10\20FieldDescriptorProto\18\12\10\4name"..
   "\24\1 \1(\9\18\14\10\6number\24\3 \1(\5\18:\10\5label\24\4 \1(\0142+.goo"..
   "gle.protobuf.FieldDescriptorProto.Label\0188\10\4type\24\5 \1(\0142*.goo"..
   "gle.protobuf.FieldDescriptorProto.Type\18\17\10\9type_name\24\6 \1(\9\18"..
   "\16\10\8extendee\24\2 \1(\9\18\21\10\13default_value\24\7 \1(\9\18\19\10"..
   "\11oneof_index\24\9 \1(\5\18\17\10\9json_name\24\10 \1(\9\18.\10\7option"..
   "s\24\8 \1(\0112\29.google.protobuf.FieldOptions\"\182\2\10\4Type\18\15\10"..
   "\11TYPE_DOUBLE\16\1\18\14\10\10TYPE_FLOAT\16\2\18\14\10\10TYPE_INT64\16\3"..
   "\18\15\10\11TYPE_UINT64\16\4\18\14\10\10TYPE_INT32\16\5\18\16\10\12TYPE_"..
   "FIXED64\16\6\18\16\10\12TYPE_FIXED32\16\7\18\13\10\9TYPE_BOOL\16\8\18\15"..
   "\10\11TYPE_STRING\16\9\18\14\10\10TYPE_GROUP\16\10\18\16\10\12TYPE_MESSA"..
   "GE\16\11\18\14\10\10TYPE_BYTES\16\12\18\15\10\11TYPE_UINT32\16\13\18\13\10"..
   "\9TYPE_ENUM\16\14\18\17\10\13TYPE_SFIXED32\16\15\18\17\10\13TYPE_SFIXED6"..
   "4\16\16\18\15\10\11TYPE_SINT32\16\17\18\15\10\11TYPE_SINT64\16\18\"C\10\5"..
   "Label\18\18\10\14LABEL_OPTIONAL\16\1\18\18\10\14LABEL_REQUIRED\16\2\18\18"..
   "\10\14LABEL_REPEATED\16\3\"T\10\20OneofDescriptorProto\18\12\10\4name\24"..
   "\1 \1(\9\18.\10\7options\24\2 \1(\0112\29.google.protobuf.OneofOptions\""..
   "\164\2\10\19EnumDescriptorProto\18\12\10\4name\24\1 \1(\9\0188\10\5value"..
   "\24\2 \3(\0112).google.protobuf.EnumValueDescriptorProto\18-\10\7options"..
   "\24\3 \1(\0112\28.google.protobuf.EnumOptions\18N\10\14reserved_range\24"..
   "\4 \3(\01126.google.protobuf.EnumDescriptorProto.EnumReservedRange\18\21"..
   "\10\13reserved_name\24\5 \3(\9\26/\10\17EnumReservedRange\18\13\10\5star"..
   "t\24\1 \1(\5\18\11\10\3end\24\2 \1(\5\"l\10\24EnumValueDescriptorProto\18"..
   "\12\10\4name\24\1 \1(\9\18\14\10\6number\24\2 \1(\5\0182\10\7options\24\3"..
   " \1(\0112!.google.protobuf.EnumValueOptions\"\144\1\10\22ServiceDescript"..
   "orProto\18\12\10\4name\24\1 \1(\9\0186\10\6method\24\2 \3(\0112&.google."..
   "protobuf.MethodDescriptorProto\0180\10\7options\24\3 \1(\0112\31.google."..
   "protobuf.ServiceOptions\"\193\1\10\21MethodDescriptorProto\18\12\10\4nam"..
   "e\24\1 \1(\9\18\18\10\10input_type\24\2 \1(\9\18\19\10\11output_type\24\3"..
   " \1(\9\18/\10\7options\24\4 \1(\0112\30.google.protobuf.MethodOptions\18"..
   "\31\10\16client_streaming\24\5 \1(\8:\5false\18\31\10\16server_streaming"..
   "\24\6 \1(\8:\5false\"\240\5\10\11FileOptions\18\20\10\12java_package\24\1"..
   " \1(\9\18\28\10\20java_outer_classname\24\8 \1(\9\18\"\10\19java_multipl"..
   "e_files\24\10 \1(\8:\5false\18)\10\29java_generate_equals_and_hash\24\20"..
   " \1(\8B\2\24\1\18%\10\22java_string_check_utf8\24\27 \1(\8:\5false\18F\10"..
   "\12optimize_for\24\9 \1(\0142).google.protobuf.FileOptions.OptimizeMode:"..
   "\5SPEED\18\18\10\10go_package\24\11 \1(\9\18\"\10\19cc_generic_services\24"..
   "\16 \1(\8:\5false\18$\10\21java_generic_services\24\17 \1(\8:\5false\18\""..
   "\10\19py_generic_services\24\18 \1(\8:\5false\18#\10\20php_generic_servi"..
   "ces\24* \1(\8:\5false\18\25\10\10deprecated\24\23 \1(\8:\5false\18\31\10"..
   "\16cc_enable_arenas\24\31 \1(\8:\5false\18\25\10\17objc_class_prefix\24$"..
   " \1(\9\18\24\10\16csharp_namespace\24% \1(\9\18\20\10\12swift_prefix\24'"..
   " \1(\9\18\24\10\16php_class_prefix\24( \1(\9\18\21\10\13php_namespace\24"..
   ") \1(\9\18C\10\20uninterpreted_option\24\231\7 \3(\0112$.google.protobuf"..
   ".UninterpretedOption\":\10\12OptimizeMode\18\9\10\5SPEED\16\1\18\13\10\9"..
   "CODE_SIZE\16\2\18\16\10\12LITE_RUNTIME\16\3*\9\8\232\7\16\128\128\128\128"..
   "\2J\4\8&\16'\"\242\1\10\14MessageOptions\18&\10\23message_set_wire_forma"..
   "t\24\1 \1(\8:\5false\18.\10\31no_standard_descriptor_accessor\24\2 \1(\8"..
   ":\5false\18\25\10\10deprecated\24\3 \1(\8:\5false\18\17\10\9map_entry\24"..
   "\7 \1(\8\18C\10\20uninterpreted_option\24\231\7 \3(\0112$.google.protobu"..
   "f.UninterpretedOption*\9\8\232\7\16\128\128\128\128\2J\4\8\8\16\9J\4\8\9"..
   "\16\10\"\158\3\10\12FieldOptions\18:\10\5ctype\24\1 \1(\0142#.google.pro"..
   "tobuf.FieldOptions.CType:\6STRING\18\14\10\6packed\24\2 \1(\8\18?\10\6js"..
   "type\24\6 \1(\0142$.google.protobuf.FieldOptions.JSType:\9JS_NORMAL\18\19"..
   "\10\4lazy\24\5 \1(\8:\5false\18\25\10\10deprecated\24\3 \1(\8:\5false\18"..
   "\19\10\4weak\24\10 \1(\8:\5false\18C\10\20uninterpreted_option\24\231\7 "..
   "\3(\0112$.google.protobuf.UninterpretedOption\"/\10\5CType\18\10\10\6STR"..
   "ING\16\0\18\8\10\4CORD\16\1\18\16\10\12STRING_PIECE\16\2\"5\10\6JSType\18"..
   "\13\10\9JS_NORMAL\16\0\18\13\10\9JS_STRING\16\1\18\13\10\9JS_NUMBER\16\2"..
   "*\9\8\232\7\16\128\128\128\128\2J\4\8\4\16\5\"^\10\12OneofOptions\18C\10"..
   "\20uninterpreted_option\24\231\7 \3(\0112$.google.protobuf.Uninterpreted"..
   "Option*\9\8\232\7\16\128\128\128\128\2\"\147\1\10\11EnumOptions\18\19\10"..
   "\11allow_alias\24\2 \1(\8\18\25\10\10deprecated\24\3 \1(\8:\5false\18C\10"..
   "\20uninterpreted_option\24\231\7 \3(\0112$.google.protobuf.Uninterpreted"..
   "Option*\9\8\232\7\16\128\128\128\128\2J\4\8\5\16\6\"}\10\16EnumValueOpti"..
   "ons\18\25\10\10deprecated\24\1 \1(\8:\5false\18C\10\20uninterpreted_opti"..
   "on\24\231\7 \3(\0112$.google.protobuf.UninterpretedOption*\9\8\232\7\16\128"..
   "\128\128\128\2\"{\10\14ServiceOptions\18\25\10\10deprecated\24! \1(\8:\5"..
   "false\18C\10\20uninterpreted_option\24\231\7 \3(\0112$.google.protobuf.U"..
   "ninterpretedOption*\9\8\232\7\16\128\128\128\128\2\"\173\2\10\13MethodOp"..
   "tions\18\25\10\10deprecated\24! \1(\8:\5false\18_\10\17idempotency_level"..
   "\24\" \1(\0142/.google.protobuf.MethodOptions.IdempotencyLevel:\19IDEMPO"..
   "TENCY_UNKNOWN\18C\10\20uninterpreted_option\24\231\7 \3(\0112$.google.pr"..
   "otobuf.UninterpretedOption\"P\10\16IdempotencyLevel\18\23\10\19IDEMPOTEN"..
   "CY_UNKNOWN\16\0\18\19\10\15NO_SIDE_EFFECTS\16\1\18\14\10\10IDEMPOTENT\16"..
   "\2*\9\8\232\7\16\128\128\128\128\2\"\158\2\10\19UninterpretedOption\18;\10"..
   "\4name\24\2 \3(\0112-.google.protobuf.UninterpretedOption.NamePart\18\24"..
   "\10\16identifier_value\24\3 \1(\9\18\26\10\18positive_int_value\24\4 \1("..
   "\4\18\26\10\18negative_int_value\24\5 \1(\3\18\20\10\12double_value\24\6"..
   " \1(\1\18\20\10\12string_value\24\7 \1(\12\18\23\10\15aggregate_value\24"..
   "\8 \1(\9\0263\10\8NamePart\18\17\10\9name_part\24\1 \2(\9\18\20\10\12is_"..
   "extension\24\2 \2(\8\"\213\1\10\14SourceCodeInfo\18:\10\8location\24\1 \3"..
   "(\0112(.google.protobuf.SourceCodeInfo.Location\26\134\1\10\8Location\18"..
   "\16\10\4path\24\1 \3(\5B\2\16\1\18\16\10\4span\24\2 \3(\5B\2\16\1\18\24\10"..
   "\16leading_comments\24\3 \1(\9\18\25\10\17trailing_comments\24\4 \1(\9\18"..
   "!\10\25leading_detached_comments\24\6 \3(\9\"\167\1\10\17GeneratedCodeIn"..
   "fo\18A\10\10annotation\24\1 \3(\0112-.google.protobuf.GeneratedCodeInfo."..
   "Annotation\26O\10\10Annotation\18\16\10\4path\24\1 \3(\5B\2\16\1\18\19\10"..
   "\11source_file\24\2 \1(\9\18\13\10\5begin\24\3 \1(\5\18\11\10\3end\24\4 "..
   "\1(\5B\143\1\10\19com.google.protobufB\16DescriptorProtosH\1Z>github.com"..
   "/golang/protobuf/protoc-gen-go/descriptor;descriptor\248\1\1\162\2\3GPB\170"..
   "\2\26Google.Protobuf.Reflection"

function Parser.reload()
   assert(pb.load(descriptor_pb), "load descriptor msg failed")
end

local function do_compile(self, f, ...)
   if self.include_imports then
      local old = self.on_import
      local infos = {}
      function self.on_import(info)
         insert_tab(infos, info)
      end
      local r = f(...)
      insert_tab(infos, r)
      self.on_import = old
      return { file = infos }
   end
   return { file = { f(...) } }
end

function Parser:compile(s, name)
   if self == Parser then self = Parser.new() end
   local set = do_compile(self, self.parse, self, s, name)
   return pb.encode('.google.protobuf.FileDescriptorSet', set)
end

function Parser:compilefile(fn)
   if self == Parser then self = Parser.new() end
   local set = do_compile(self, self.parsefile, self, fn)
   return pb.encode('.google.protobuf.FileDescriptorSet', set)
end

function Parser:load(s, name)
   if self == Parser then self = Parser.new() end
   local ret, pos = pb.load(self:compile(s, name))
   if ret then return ret, pos end
   error("load failed at offset "..pos)
end

function Parser:loadfile(fn)
   if self == Parser then self = Parser.new() end
   local ret, pos = pb.load(self:compilefile(fn))
   if ret then return ret, pos end
   error("load failed at offset "..pos)
end

Parser.reload()

end
end

return Parser
