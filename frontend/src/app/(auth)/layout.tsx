export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-gray-900 via-blue-950 to-indigo-950 p-4">
      <div className="absolute -top-40 -right-40 w-[500px] h-[500px] bg-blue-500/20 rounded-full blur-3xl animate-pulse-slow" />
      <div className="absolute -bottom-40 -left-40 w-[500px] h-[500px] bg-indigo-500/20 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: "2s" }} />
      <div className="absolute top-1/3 left-1/4 w-[300px] h-[300px] bg-purple-500/10 rounded-full blur-3xl animate-float" />
      <div className="absolute bottom-1/4 right-1/4 w-[200px] h-[200px] bg-cyan-500/10 rounded-full blur-3xl animate-float" style={{ animationDelay: "3s" }} />
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:64px_64px]" />
      <div className="relative w-full max-w-md animate-fade-in">
        {children}
      </div>
    </div>
  )
}
