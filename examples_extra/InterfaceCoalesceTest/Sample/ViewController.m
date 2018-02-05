/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>

#define NUMBER_ELEMENTS 2

@interface ViewController ()
{
  ASButtonNode *_node;
}

@end


@implementation ViewController

+(void)initialize {
  [[ASCATransactionQueue sharedQueue] disableInterfaceStateCoalesce];
}
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _node = [[ASButtonNode alloc] init];
  _node.frame = CGRectMake(0, 100, 100, 100);
  _node.backgroundColor = [UIColor greenColor];

  [self.view addSubnode:_node];
  [_node addTarget:self action:@selector(clicked:) forControlEvents:ASControlNodeEventTouchUpInside];
}

- (void)clicked:(id)sender {
  ViewController *vc = [[ViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

@end
