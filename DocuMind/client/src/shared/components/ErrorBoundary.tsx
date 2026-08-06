import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught:', error);
    console.error('Component stack:', errorInfo.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-white p-8">
          <div className="border-4 border-red-500 p-6 max-w-2xl mx-auto">
            <h1 className="text-2xl font-bold text-red-600 mb-4">Something went wrong</h1>
            <div className="bg-gray-100 p-4 rounded font-mono text-sm overflow-auto">
              <p className="font-semibold">Error: {this.state.error?.message}</p>
              <details className="mt-2">
                <summary className="cursor-pointer text-blue-600">Stack trace</summary>
                <pre className="text-xs mt-2 whitespace-pre-wrap text-gray-700">
                  {this.state.error?.stack}
                </pre>
              </details>
            </div>
            <button 
              onClick={() => window.location.reload()}
              className="mt-4 px-4 py-2 bg-black text-white border-2 border-black hover:bg-white hover:text-black"
            >
              Reload Page
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;