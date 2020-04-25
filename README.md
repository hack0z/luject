<div align="center">
  <h1>luject</h1>

  <div>
    <a href="https://github.com/lanoox/luject/actions?query=workflow%3Abuild">
      <img src="https://img.shields.io/github/workflow/status/lanoox/luject/build/master.svg?style=flat-square" alt="github-ci" />
    </a>
    <a href="https://github.com/lanoox/luject/releases">
      <img src="https://img.shields.io/github/release/lanoox/luject.svg?style=flat-square" alt="Github All Releases" />
    </a>
    <a href="https://github.com/lanoox/luject/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/lanoox/luject.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
  </div>
  <div>
    <a href="https://www.reddit.com/r/tboox/">
      <img src="https://img.shields.io/badge/chat-on%20reddit-ff3f34.svg?style=flat-square" alt="Reddit" />
    </a>
    <a href="https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
      <img src="https://img.shields.io/gitter/room/tboox/tboox.svg?style=flat-square&colorB=96c312" alt="Gitter" />
    </a>
    <a href="https://t.me/tbooxorg">
      <img src="https://img.shields.io/badge/chat-on%20telegram-blue.svg?style=flat-square" alt="Telegram" />
    </a>
    <a href="https://jq.qq.com/?_wv=1027&k=5hpwWFv">
      <img src="https://img.shields.io/badge/chat-on%20QQ-ff69b4.svg?style=flat-square" alt="QQ" />
    </a>
    <a href="https://xmake.io/#/sponsor">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <p>A static injector of dynamic library for application</p>
</div>

## Introduction ([中文](/README_zh.md))

luject is a static injector of dynamic library for application. It support the following applications:

* Android APK
* iPhoneOS IPA
* Windows Program
* Linux Program
* MacOS Program

If you want to know more, please refer to:

* [Documents](https://xmake.io/#/home)
* [HomePage](https://xmake.io)
* [Github](https://github.com/lanoox/luject)
* [Gitee](https://gitee.com/lanoox/luject)

## Prerequisites

XMake installed on the system. Available [here](https://github.com/xmake-io/xmake).

## Build

```console
$ xmake
```

## Installation

```console
$ xmake install
```

## Usage

```console
$ luject -i app.apk lib1.so lib2.so
$ luject -i app.ipa lib1.dylib lib2.dylib
$ luject -i liba.so lib1.so lib2.so
$ luject -i app.exe lib1.dll lib2.dll
$ luject -i a.dll lib1.dll lib2.dll
$ luject -i liba.dylib lib1.dylib lib2.dyib
$ luject -i bin lib1.so lib2.so
```

## Example 

### Inject libfrida-gadget.so to apk

Use frida tools to dynamically analyze the application. For details, see: [frida](https://github.com/frida/frida)

```console
$ luject -i app.apk -p libtest /tmp/libfrida-gadget.so
```

libtest is a so library that requires matching injection in the apk, and supports pattern matching to achieve batch injection, for example: `libtest_*.so`, 
if you do not specify the `-p` parameter, all so are defaulted for batch full injection.

refs: [How to use frida on a non-rooted device](https://lief.quarkslab.com/doc/latest/tutorials/09_frida_lief.html)

## Development

### Build and run

```console
$ xmake
$ xmake run luject -i [input] liba.so libb.so
```

### Build and run tests

```console
$ xmake build test
$ xmake run test
```

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[tboox.org](https://tboox.org)
* Community：[/r/tboox on reddit](https://www.reddit.com/r/tboox/)
* ChatRoom：[Char on telegram](https://t.me/tbooxorg), [Chat on gitter](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* QQ Group: 343118190(full), 662147501
* Wechat Public: tboox-os

## Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/xmake#backer)]

<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=890"></a>

## Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/xmake#sponsor)]

<a href="https://opencollective.com/xmake/sponsor/0/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/1/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/2/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/3/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/4/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/5/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/6/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/7/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/8/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/9/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/9/avatar.svg"></a>


