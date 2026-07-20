export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-950 via-blue-950 to-indigo-950 p-4">
      {/* Animated gradient orbs */}
      <div className="absolute -top-32 -left-32 w-[600px] h-[600px] bg-blue-600/20 rounded-full blur-[120px] animate-pulse-slow" />
      <div className="absolute -bottom-32 -right-32 w-[600px] h-[600px] bg-indigo-600/20 rounded-full blur-[120px] animate-pulse-slow" style={{ animationDelay: "2s" }} />
      <div className="absolute top-1/4 right-1/4 w-[300px] h-[300px] bg-cyan-500/10 rounded-full blur-[100px] animate-float" />
      <div className="absolute bottom-1/3 left-1/4 w-[250px] h-[250px] bg-purple-500/10 rounded-full blur-[100px] animate-float" style={{ animationDelay: "3s" }} />

      {/* Subtle grid overlay */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:72px_72px]" />

      {/* Radial fade from center */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_0%,rgba(0,0,0,0.3)_100%)]" />

      {/* Content */}
      <div className="relative z-10 w-full max-w-md animate-fade-in">
        {children}
      </div>
    </div>
  )
}