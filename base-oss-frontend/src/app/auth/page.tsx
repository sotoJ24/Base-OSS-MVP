"use client"

import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Github, Code2 } from "lucide-react"
import Link from "next/link"
import { useRouter } from "next/navigation"

export default function AuthPage() {
  const router = useRouter()

  const handleGithubSignIn = () => {
    // TODO: Integrate with Privy for GitHub authentication
    // For now, simulate sign in and redirect to onboarding
    console.log("[v0] GitHub sign in clicked")
    router.push("/onboarding")
  }

  const handleBaseSignIn = () => {
    // TODO: Integrate with Privy for Base wallet authentication
    console.log("[v0] Base wallet sign in clicked")
    router.push("/onboarding")
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2 mb-8">
          <Code2 className="h-8 w-8 text-primary" />
          <span className="text-2xl font-bold">Base OSS Match</span>
        </div>

        {/* Auth Card */}
        <Card className="p-8 bg-card border-border">
          <div className="text-center mb-6">
            <h1 className="text-2xl font-bold mb-2">Welcome Back</h1>
            <p className="text-muted-foreground">Sign in to start contributing to Base ecosystem projects</p>
          </div>

          <div className="space-y-4">
            <Button onClick={handleGithubSignIn} className="w-full gap-2" size="lg">
              <Github className="h-5 w-5" />
              Continue with GitHub
            </Button>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t border-border" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">Or</span>
              </div>
            </div>

            <Button onClick={handleBaseSignIn} variant="outline" className="w-full gap-2 bg-transparent" size="lg">
              <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="10" />
              </svg>
              Continue with Base Wallet
            </Button>
          </div>

          <p className="text-xs text-muted-foreground text-center mt-6">
            By continuing, you agree to our Terms of Service and Privacy Policy
          </p>
        </Card>

        {/* Back to Home */}
        <div className="text-center mt-6">
          <Link href="/" className="text-sm text-muted-foreground hover:text-foreground">
            Back to home
          </Link>
        </div>
      </div>
    </div>
  )
}
