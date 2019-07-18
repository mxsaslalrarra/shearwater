module matrix.api;

import std.meta : aliasSeqOf;
import std.range : chain;

public import matrix.api.login;

alias ApiMembers = aliasSeqOf!([
  __traits(allMembers, matrix.api.login)
]);