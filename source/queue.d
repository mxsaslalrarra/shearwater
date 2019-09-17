module queue;

import std.container : DList;
import std.meta : AliasSeq;
import std.stdio : writeln;
import std.string : toLower;
import std.typecons : Nullable, nullable;

import core.thread : dur, Thread;

import matrix;
import matrix.api;

// TODO
// 1. Use Fibers for each queue rather than a direct DList

static foreach (Method; Methods)
{
  // All interaction with these queues should be done via `put` and `take`
  mixin(`private __gshared static auto main_queue_` ~ Method.toLower ~
        ` = DList!(` ~ Method ~ `!(Kind.Response))();`);
  mixin(`private __gshared static auto work_queue_` ~ Method.toLower ~
        ` = DList!(` ~ Method ~ `!(Kind.Request))();`);
}

auto ref Q(string group, string method)()
{
  static assert (group == "main" || group == "work");
  return mixin(group ~ `_queue_` ~ method.toLower);
}

auto ref MQ(string method)() { return Q!("main", method)(); }
auto ref WQ(string method)() { return Q!("work", method)(); }

T popFront(T)(ref DList!T queue)
{
  T result = queue.front;
  queue.removeFront();
  return result;
}

unittest
{
  import std.range : popFront;
  DList!int queue = DList!int();
  queue ~= 10;
  int result = queue.popFront();
  assert(result == 10);
  assert(queue.empty);
}

unittest
{
  import std.array : array;

  DList!int queue = DList!int();
  queue.insertFront([1, 2, 3]);

  int result = queue.popFront();
  assert(result == 1);
  assert(queue.array == [2, 3]);
}

unittest
{
  auto queue = DList!(Request!Sync)();
  auto request = Request!Sync();
  queue.insertFront(request);

  auto result = queue.popFront();
  assert(result.method == "GET");
  assert(is(typeof(result) == Request!Sync));
}

//

/++
 + Place a Request or Response on the relevant queue.
 +/
void put(T)(T value)
{
  import std.string : toLower;
  import std.traits : TemplateArgsOf;

  static foreach (Method; Methods)
  {
    static if (methodMatches!(Method, T))
    {
      synchronized
      {
        static if (TemplateArgsOf!(T)[0] == Kind.Request)
        {
          WQ!(Method.toLower) ~= value;
        }
        else
        {
          MQ!(Method.toLower) ~= value;
        }
      }
    }
  }
}

unittest
{
  {
    auto request = Request!Sync();
    put(request);

    assert(work_queue_sync.front == request);
    assert(work_queue_login.empty);
    assert(main_queue_sync.empty);
    assert(main_queue_login.empty);

    work_queue_sync.removeFront();
  }

  {
    auto request = Request!Login();
    put(request);

    assert(work_queue_login.front == request);
    assert(work_queue_sync.empty);
    assert(main_queue_sync.empty);
    assert(main_queue_login.empty);

    work_queue_login.removeFront();
  }

  {
    auto response = Response!Sync();
    put(response);

    assert(main_queue_sync.front == response);
    assert(main_queue_login.empty);
    assert(work_queue_login.empty);
    assert(work_queue_sync.empty);

    main_queue_sync.removeFront();
  }

  {
    auto response = Response!Login();
    put(response);

    assert(main_queue_login.front == response);
    assert(main_queue_sync.empty);
    assert(work_queue_login.empty);
    assert(work_queue_sync.empty);

    main_queue_login.removeFront();
  }
}

/++
 + Take a Request or Response from the relevant queue.
 + Blocks by default.
 + If Blocking is false then this may raise an AssertionError from
 + DList if the queue is empty.
 +/
Nullable!T take(T, bool Blocking = false)()
{
  import std.string : toLower;
  import std.traits : TemplateArgsOf;

  Nullable!T result;

  static foreach (Method; Methods)
  {
    static if (methodMatches!(Method, T))
    {
      synchronized
      {
        static if (TemplateArgsOf!(T)[0] == Kind.Request)
        {
          auto queue = WQ!(Method.toLower);
        }
        else
        {
          auto queue = MQ!(Method.toLower);
        }

        static if (Blocking)
        {
          while (queue.empty)
          {
            Thread.sleep(dur!"msecs"( 0 ));
          }
        }

        if (!queue.empty)
        {
          result = queue.popFront();
        }
        else
        {
          result.nullify();
        }
      }
    }
  }

  return result;
}

unittest
{
  {
    auto request = Request!Sync();
    put(request);
    assert(!work_queue_sync.empty);

    auto result = take!(Request!Sync)();

    assert(!result.isNull);
    assert(result == request);
    assert(work_queue_sync.empty);
  }

  {
    auto request = Request!Login();
    put(request);
    assert(!work_queue_login.empty);

    auto result = take!(Request!Login)();

    assert(!result.isNull);
    assert(result == request);
    assert(work_queue_login.empty);
  }

  {
    auto request = Response!Sync();
    put(request);
    assert(!main_queue_sync.empty);

    auto result = take!(Response!Sync)();

    assert(!result.isNull);
    assert(result == request);
    assert(main_queue_sync.empty);
  }

  {
    auto request = Response!Login();
    put(request);
    assert(!main_queue_login.empty);

    auto result = take!(Response!Login)();

    assert(!result.isNull);
    assert(result == request);
    assert(main_queue_login.empty);
  }
}

unittest
{
  {
    assert(work_queue_sync.empty);

    auto result = take!(Request!Sync, false)();

    assert(work_queue_sync.empty);
    assert(result.isNull);
  }

  {
    assert(work_queue_login.empty);

    auto result = take!(Request!Login, false)();

    assert(work_queue_login.empty);
    assert(result.isNull);
  }

  {
    assert(main_queue_sync.empty);

    auto result = take!(Response!Sync, false)();

    assert(main_queue_sync.empty);
    assert(result.isNull);
  }

  {
    assert(main_queue_login.empty);

    auto result = take!(Response!Login, false)();

    assert(main_queue_login.empty);
    assert(result.isNull);
  }
}
