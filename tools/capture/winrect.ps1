Add-Type @'
using System;
using System.Runtime.InteropServices;
public class W { [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r); }
public struct RECT { public int Left, Top, Right, Bottom; }
'@
$p = Get-Process love -ErrorAction SilentlyContinue
if ($p) {
  $r = New-Object RECT
  [W]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
  "$($r.Left) $($r.Top) $($r.Right) $($r.Bottom)"
} else { 'no love process' }
