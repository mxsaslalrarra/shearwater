module matrix.api;

import std.meta : aliasSeqOf;
import std.range : chain;

public import matrix.api.login;
public import matrix.api.sync;
public import matrix.api.filter;

alias ApiMembers = aliasSeqOf!(chain(
  [__traits(allMembers, matrix.api.login)],
  [__traits(allMembers, matrix.api.sync)],
  [__traits(allMembers, matrix.api.filter)],
));
