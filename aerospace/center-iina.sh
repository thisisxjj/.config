#!/usr/bin/env bash
set -euo pipefail

osascript -l JavaScript <<'JXA'
ObjC.import('AppKit');
ObjC.import('Foundation');

var homePath = ObjC.unwrap($.NSFileManager.defaultManager.homeDirectoryForCurrentUser.path);
var cfgPath = homePath + '/.config/aerospace/aerospace.toml';
var cfgText = $.NSString.stringWithContentsOfFileEncodingError(cfgPath, $.NSUTF8StringEncoding, null);
var cfg = cfgText ? ObjC.unwrap(cfgText) : '';

function parseOuterGap(side) {
  var re = new RegExp('^[ \\t]*outer\\.' + side + '[ \\t]*=[ \\t]*(-?[0-9]+)[ \\t]*$', 'm');
  var m = cfg.match(re);
  if (!m) return 0;
  var v = parseInt(m[1], 10);
  return isNaN(v) ? 0 : v;
}

var gapLeft = parseOuterGap('left');
var gapRight = parseOuterGap('right');
var gapTop = parseOuterGap('top');
var gapBottom = parseOuterGap('bottom');

var se = Application('System Events');
var proc = se.processes.byName('IINA');

(function () {
  var win = null;
  try {
    win = proc.windows[0];
  } catch (_) {
    return;
  }
  if (!win) return;

  $.NSThread.sleepForTimeInterval(0.08);

  var pos;
  var size;
  try {
    pos = win.position();
    size = win.size();
  } catch (_) {
    return;
  }

  var centerX = pos[0] + size[0] / 2;
  var centerY = pos[1] + size[1] / 2;

  var screens = $.NSScreen.screens;
  var targetScreen = null;

  for (var i = 0; i < screens.count; i++) {
    var s = screens.objectAtIndex(i);
    var v = s.visibleFrame;
    var minX = v.origin.x;
    var minY = v.origin.y;
    var maxX = minX + v.size.width;
    var maxY = minY + v.size.height;

    if (centerX >= minX && centerX <= maxX && centerY >= minY && centerY <= maxY) {
      targetScreen = s;
      break;
    }
  }

  if (targetScreen === null) {
    targetScreen = $.NSScreen.mainScreen;
  }

  var visible = targetScreen.visibleFrame;
  var targetX = Math.round(visible.origin.x + gapLeft);
  var targetY = Math.round(visible.origin.y + gapTop);
  var targetW = Math.max(200, Math.round(visible.size.width - gapLeft - gapRight));
  var targetH = Math.max(120, Math.round(visible.size.height - gapTop - gapBottom));

  var ratio = size[0] / size[1];
  var newW = targetW;
  var newH = targetH;

  if (isFinite(ratio) && ratio > 0) {
    if (targetW / targetH >= ratio) {
      newH = targetH;
      newW = Math.round(newH * ratio);
    } else {
      newW = targetW;
      newH = Math.round(newW / ratio);
    }
  }

  newW = Math.max(200, Math.min(targetW, newW));
  newH = Math.max(120, Math.min(targetH, newH));

  var centeredX = Math.round(targetX + (targetW - newW) / 2);
  var centeredY = Math.round(targetY + (targetH - newH) / 2);
  var frame = targetScreen.frame;
  var axY = Math.round(frame.origin.y + frame.size.height - (centeredY + newH));

  for (var j = 0; j < 3; j++) {
    try {
      win.size = [newW, newH];
      win.position = [centeredX, axY];
    } catch (_) {
      return;
    }
    $.NSThread.sleepForTimeInterval(0.1);
  }
})();
JXA
