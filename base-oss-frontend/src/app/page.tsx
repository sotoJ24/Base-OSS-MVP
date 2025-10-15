import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Github, Code2, Users, Zap } from "lucide-react"
import Link from "next/link"

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Code2 className="h-6 w-6 text-primary" />
            <span className="text-xl font-semibold">Base OSS Match</span>
          </div>
          <Link href="/auth">
            <Button variant="outline" className="gap-2 bg-transparent">
              <Github className="h-4 w-4" />
              Sign In
            </Button>
          </Link>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 md:py-32">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl md:text-6xl font-bold mb-6 text-balance">
            Connect with <span className="text-primary">Base Ecosystem</span> Projects
          </h1>
          <p className="text-xl text-muted-foreground mb-8 text-pretty leading-relaxed">
            Match OSS contributors with relevant projects in the Base ecosystem. Find issues that match your skills,
            contribute to meaningful projects, and earn rewards.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/auth">
              <Button size="lg" className="gap-2 w-full sm:w-auto">
                <Github className="h-5 w-5" />
                Get Started
              </Button>
            </Link>
            <Link href="/browse">
              <Button size="lg" variant="outline" className="w-full sm:w-auto bg-transparent">
                Browse Projects
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto px-4 py-20">
        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          <Card className="p-6 bg-card border-border">
            <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
              <Users className="h-6 w-6 text-primary" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Smart Matching</h3>
            <p className="text-muted-foreground leading-relaxed">
              Get matched with projects based on your tech stack, interests, and experience level.
            </p>
          </Card>

          <Card className="p-6 bg-card border-border">
            <div className="h-12 w-12 rounded-lg bg-accent/10 flex items-center justify-center mb-4">
              <Code2 className="h-6 w-6 text-accent" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Quality Projects</h3>
            <p className="text-muted-foreground leading-relaxed">
              Discover vetted Base ecosystem projects with clear issues and maintainer support.
            </p>
          </Card>

          <Card className="p-6 bg-card border-border">
            <div className="h-12 w-12 rounded-lg bg-chart-3/10 flex items-center justify-center mb-4">
              <Zap className="h-6 w-6 text-chart-3" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Earn Rewards</h3>
            <p className="text-muted-foreground leading-relaxed">
              Receive tips via tip.md for your contributions and build your reputation.
            </p>
          </Card>
        </div>
      </section>

      {/* How It Works */}
      <section className="container mx-auto px-4 py-20">
        <div className="max-w-3xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">How It Works</h2>
          <div className="space-y-8">
            <div className="flex gap-4">
              <div className="flex-shrink-0 h-10 w-10 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-semibold">
                1
              </div>
              <div>
                <h3 className="text-xl font-semibold mb-2">Sign In & Set Up Profile</h3>
                <p className="text-muted-foreground leading-relaxed">
                  Connect with GitHub or Base wallet and tell us about your skills and interests.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex-shrink-0 h-10 w-10 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-semibold">
                2
              </div>
              <div>
                <h3 className="text-xl font-semibold mb-2">Browse & Apply</h3>
                <p className="text-muted-foreground leading-relaxed">
                  Discover projects filtered by tech stack and topics. Apply to issues that match your expertise.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex-shrink-0 h-10 w-10 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-semibold">
                3
              </div>
              <div>
                <h3 className="text-xl font-semibold mb-2">Contribute & Earn</h3>
                <p className="text-muted-foreground leading-relaxed">
                  Submit your PR, get it reviewed, and receive tips for your valuable contributions.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="container mx-auto px-4 py-20">
        <Card className="max-w-3xl mx-auto p-8 md:p-12 text-center bg-card border-border">
          <h2 className="text-3xl font-bold mb-4">Ready to Start Contributing?</h2>
          <p className="text-muted-foreground mb-6 text-lg leading-relaxed">
            Join the Base ecosystem and make meaningful contributions today.
          </p>
          <Link href="/auth">
            <Button size="lg" className="gap-2">
              <Github className="h-5 w-5" />
              Sign In with GitHub
            </Button>
          </Link>
        </Card>
      </section>

      {/* Footer */}
      <footer className="border-t border-border mt-20">
        <div className="container mx-auto px-4 py-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-2">
              <Code2 className="h-5 w-5 text-primary" />
              <span className="font-semibold">Base OSS Match</span>
            </div>
            <p className="text-sm text-muted-foreground">Built for the Base ecosystem buildathon</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
